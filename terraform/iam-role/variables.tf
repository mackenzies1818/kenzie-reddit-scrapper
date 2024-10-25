variable "aws_region" {
  description = "Name of the AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_role_arn" {
  description = "ARN of the AWS role to assume when running terraform"
  type        = string
  default     = "arn:aws:iam::992382748278:role/terraform-role"
}

variable "aws_user" {
  description = "Name of the AWS user to create the role"
  type        = string
  default     = "kenzie-poweruser"
}

variable "aws_user_arn" {
  description = "ARN of the AWS user to create the role"
  type        = string
  default     = "arn:aws:iam::992382748278:user/kenzie-poweruser"
}