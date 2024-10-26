provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = var.aws_role_arn
    session_name = "terraform-session"
  }
}

resource "aws_ecr_repository" "kenzie_ecr_repo" {
  name                 = "kenzie_ecr_repo"  # Replace with your desired repository name
  image_tag_mutability = "MUTABLE" # Choose "MUTABLE" or "IMMUTABLE" based on your needs
  image_scanning_configuration {
    scan_on_push = true           # Enables scanning of images on push
  }
}

