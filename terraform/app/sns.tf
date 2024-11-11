# Create an SNS topic
resource "aws_sns_topic" "reddit_sns_topic" {
  name = var.reddit_sns_topic
}

# Create an SQS policy that allows SNS to send messages to the SQS queue
resource "aws_sqs_queue_policy" "example_sqs_queue_policy" {
  queue_url = aws_sqs_queue.reddit_queue.id

  policy = jsonencode({
    "Version"   : "2012-10-17",
    "Statement" : [
      {
        "Effect"    : "Allow",
        "Principal" : "*",
        "Action"    : "sqs:SendMessage",
        "Resource"  : aws_sqs_queue.reddit_queue.arn,
        "Condition" : {
          "ArnEquals" : {
            "aws:SourceArn" : aws_sns_topic.reddit_sns_topic.arn
          }
        }
      }
    ]
  })
}

# Create an SNS subscription to send email notifications
resource "aws_sns_topic_subscription" "reddit_email_subscription" {
  topic_arn = aws_sns_topic.reddit_sns_topic.arn
  protocol  = "email"
  endpoint  = var.sns_receiver_email
}
