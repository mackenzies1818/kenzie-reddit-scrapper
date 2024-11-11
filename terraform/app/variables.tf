variable "kinesis_stream_name" {
  description = "Name of the Kinesis stream"
  type        = string
  default     = "kenzie-reddit-stream"
}

variable "kinesis_stream_consumer_name" {
  description = "Name of the Kinesis stream consumer"
  type        = string
  default     = "kenzie-reddit-stream-consumer"
}

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

variable "lambda_s3_bucket_name" {
  description = "Name of the S3 bucket where the lambda function will be stored"
  type        = string
  default     = "kenzie-kinesis-consumer-lambda-data"
}

variable "lambda_s3_key" {
  description = "Name of the zipped file with the lambda function"
  type        = string
  default     = "kenzie-kinesis-consumer-lambda"
}

variable "lambda_s3_source" {
  description = "Local path where the zipped file of the lambda is"
  type        = string
  default     = "lambda/lambda_handler-v2.zip"
}

variable "lambda_function_name" {
  description = "Name of the function to call in the lambda"
  type        = string
  default     = "lambda_handler"
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