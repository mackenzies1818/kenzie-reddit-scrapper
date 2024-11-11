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

variable "lambda_recipient_email" {
  description = "Recipient email for SES"
  type        = string
  default     = "mackenzielsheridan+recipient@gmail.com"
}

variable "lambda_sender_email" {
  description = "Sender email for SES"
  type        = string
  default     = "mackenzielsheridan+sender@gmail.com"
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

variable "ec2_codedeploy_app_name" {
  description = "Sender email for SES"
  type        = string
  default     = "kenzie-ec2-reddit-deployment-app"
}

variable "ec2_deploy_deployment_group_name" {
  description = "Sender email for SES"
  type        = string
  default     = "kenzie-ec2-reddit-deployment-group"
}

variable "ec2_reddit_secrets_arn" {
  description = "Sender email for SES"
  type        = string
  default     = "arn:aws:secretsmanager:us-east-1:992382748278:secret:kenzie-reddit-secrets-x3LUQT"
}

variable "artifact_bucket_name" {
  description = "Sender email for SES"
  type        = string
  default     = "kenzie-pipeline-artifacts"
}