resource "aws_sqs_queue" "reddit_queue" {
  name = var.sqs_queue_name
  # Optional attributes for delay, retention, etc.
  delay_seconds            = 0
  message_retention_seconds = 86400
  visibility_timeout_seconds = 60  # Match or exceed the Lambda timeout
}
