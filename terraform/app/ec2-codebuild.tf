resource "aws_iam_role" "codebuild_role" {
  name = "CodeBuildEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codebuild_policy" {
  name = "CodeBuildEC2Policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.pipeline_bucket.arn,
          "${aws_s3_bucket.pipeline_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codepipeline:GetPipelineExecution",
          "codepipeline:GetPipeline",
          "codepipeline:ListPipelineExecutions"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:*"
        ]
        Resource = [
          "arn:aws:codeconnections:us-east-1:992382748278:connection/5e87dee8-00e8-47b9-80e0-141baa41fb2b"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue"
        ],
        Resource = var.ec2_reddit_secrets_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_role_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

resource "aws_codebuild_project" "reddit_ec2_codebuild" {
  name          = "reddit-ec2-build"
  service_role  = aws_iam_role.codebuild_role.arn  # Define with permissions to ECR

  artifacts {
    type = "CODEPIPELINE" # could use type s3 when there is a need to keep a copy of build artifacts, using codepipelien type does not explicitly store the artifacts in s3
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.kenzie_ecr_repo.repository_url
    }

    environment_variable {
      name  = "SECRETS_ARN"
      value = var.ec2_reddit_secrets_arn
    }
  }

  source {
    type      = "CODEPIPELINE"
  }
}