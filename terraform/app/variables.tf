variable "aws_region" {
  description = "Name of the AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_role_arn" {
  description = "Name of the AWS role to assume when running terraform"
  type        = string
  default     = "arn:aws:iam::992382748278:role/terraform-role"
}

variable "sns_receiver_email" {
  description = "Recipient email for SES"
  type        = string
  default     = "mackenzielsheridan+recipient@gmail.com"
}

variable "sqs_queue_name" {
  description = "Queue name that consumes from reddit"
  type        = string
  default     = "reddit-queue"
}

variable "reddit_sns_topic" {
  description = "SNS topic name that consumes from reddit queue"
  type        = string
  default     = "reddit-sns-topic"
}