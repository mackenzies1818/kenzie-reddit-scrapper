#create s3 bucket to store pipeline artifacts
resource "aws_s3_bucket" "pipeline_bucket" {
  bucket = var.artifact_bucket_name
}

#connection for pipeline to connect to github
data "aws_codestarconnections_connection" "github_connection_v2" {
  name = "kenzie-connection-v2"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "CodePipelineRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codepipeline_policy" {
  name = "CodePipelinePolicy"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject",
        ],
        Resource = [
          aws_s3_bucket.pipeline_bucket.arn,
          "${aws_s3_bucket.pipeline_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
        ],
        Resource = [
          aws_codebuild_project.reddit_ec2_codebuild.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = [
          data.aws_codestarconnections_connection.github_connection_v2.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetDeploymentGroup"
        ],
        Resource = [
          aws_codedeploy_app.reddit_ec2_codedeploy_app.arn,
          aws_codedeploy_deployment_group.reddit_ec2_codedeploy_deployment_group.arn,
          "arn:aws:codedeploy:us-east-1:992382748278:deploymentconfig:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

resource "aws_codepipeline" "reddit_deployment_pipeline" {
  name     = "reddit-deployment-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_bucket.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github_connection_v2.arn
        FullRepositoryId = "mackenzies1818/kenzie-reddit-scrapper"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.reddit_ec2_codebuild.name
      }
      version = "1"
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"  # Use CodeDeploy to deploy to EC2 instances
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = var.ec2_codedeploy_app_name
        DeploymentGroupName = var.ec2_deploy_deployment_group_name
      }
      version = "1"
    }
  }
}

