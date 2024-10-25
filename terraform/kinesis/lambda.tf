locals {
  lambda_zip_hash = filemd5("lambda/lambda_handler-v2.zip")
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_kinesis_ses_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Lambda to access Kinesis and SES
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_kinesis_ses_policy"
  description = "Policy to allow Lambda to access Kinesis and SES"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams",
          "kinesis:ListShards",
          "kinesis:DescribeStreamSummary"
        ],
        Effect   = "Allow",
        Resource = aws_kinesis_stream.kenzie.arn
      },
      {
        Action   = "ses:SendEmail",
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "logs:*",
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach the policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

#create s3 bucket to store lambda function
resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = var.lambda_s3_bucket_name
}

#data "archive_file" "lambda_zip_file" {
#  type        = "zip"
#  source_file = "lambda/lambda_handler.py"
#  output_path = "lambda/lambda_handler.zip"
#}

#uploads lambda function to s3
resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_code_bucket.bucket
  key    = var.lambda_s3_key
  source = var.lambda_s3_source
  # Add the content hash to the metadata (optional)
  metadata = {
    lambda_zip_hash = local.lambda_zip_hash
  }
}

resource "aws_lambda_function" "kinesis_lambda" {
  function_name = var.lambda_function_name
  s3_bucket     = aws_s3_bucket.lambda_code_bucket.bucket
  s3_key        = aws_s3_object.lambda_zip.key
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.9"
  publish       = true
  timeout = 60

  environment {
    variables = {
      SENDER_EMAIL    = var.lambda_sender_email
      RECIPIENT_EMAIL = var.lambda_recipient_email
    }
  }

  # Trigger a new deployment if the zip hash changes
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "allow_kinesis_invoke" {
  statement_id  = "AllowExecutionFromKinesis"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kinesis_lambda.function_name
  principal     = "kinesis.amazonaws.com"
  source_arn    = aws_kinesis_stream.kenzie.arn
}

resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn = aws_kinesis_stream.kenzie.arn
  function_name    = aws_lambda_function.kinesis_lambda.arn
  starting_position = "LATEST"
  batch_size = 1
}

#verify email so that ses can send it successfully
resource "aws_ses_email_identity" "lambda_ses_email_sender" {
  email = var.lambda_sender_email
}

resource "aws_ses_email_identity" "lambda_ses_email_recipient" {
  email = var.lambda_recipient_email
}