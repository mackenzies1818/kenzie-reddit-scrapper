resource "aws_lambda_function" "sqs_to_email_lambda" {
  function_name    = "SqsToEmailLambda"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = "../../lambda/lambda_function.zip"
  source_code_hash = filebase64sha256("../../lambda/lambda_function.zip")

  environment {
    variables = {
      SQS_URL      = aws_sqs_queue.reddit_queue.id
      SES_EMAIL    = var.sns_receiver_email  # Must be verified in SES
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_sqs_ses_policy" {
  name        = "LambdaSQStoSES"
  description = "Allow Lambda to read SQS messages and send emails via SES"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.reddit_queue.arn
      },
      {
        Effect   = "Allow",
        Action   = "ses:SendEmail",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "logs:CreateLogGroup",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = "logs:CreateLogStream",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = "logs:PutLogEvents",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_ses_policy.arn
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.reddit_queue.arn
  function_name    = aws_lambda_function.sqs_to_email_lambda.arn
  batch_size       = 5  # Adjust as needed
}

resource "aws_ses_email_identity" "lambda_email" {
  email = var.sns_receiver_email
}