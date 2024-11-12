provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = var.aws_role_arn
    session_name = "terraform-session"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    github = {
      source  = "hashicorp/github"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0.0"
}
# Fetch the GitHub token from Secrets Manager
data "aws_secretsmanager_secret" "github_token" {
  name = "tf-git-token"
}

data "aws_secretsmanager_secret_version" "github_token_version" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}

# Decode the secret's value
locals {
  github_token = jsondecode(data.aws_secretsmanager_secret_version.github_token_version.secret_string)["GITHUB_TOKEN"]
}

provider "github" {
  token = local.github_token  # Reference to a variable for GitHub token
}

resource "aws_ecr_repository" "kenzie_ecr_repo" {
  name                 = "kenzie_ecr_repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true           # Enables scanning of images on push
  }
}

resource "aws_ecr_repository" "python_ecr_repo" {
  name                 = "python_ecr_repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true           # Enables scanning of images on push
  }
}

