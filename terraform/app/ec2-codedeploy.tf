resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codedeploy_policy" {
  name = "codedeploy-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject",
          "s3:ListBucket"  // Add this to ensure the role can list bucket contents
        ],
        "Resource": [
          aws_s3_bucket.pipeline_bucket.arn,
          "${aws_s3_bucket.pipeline_bucket.arn}/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "codedeploy:*", // Grant CodeDeploy access to manage deployments
          "iam:PassRole"  // Allow CodeDeploy to pass roles for deployments
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:GetDeployment",
          "tag:GetResources",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:PutLifecycleHook",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "autoscaling:DescribeAutoScalingGroups"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attach" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = aws_iam_policy.codedeploy_policy.arn
}

resource "aws_codedeploy_app" "reddit_ec2_codedeploy_app" {
  name = var.ec2_codedeploy_app_name
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "reddit_ec2_codedeploy_deployment_group" {
  app_name              = var.ec2_codedeploy_app_name
  deployment_group_name = var.ec2_deploy_deployment_group_name
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
  # Target the EC2 instance using a tag filter or instance ID
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = aws_instance.reddit_ec2_docker_service.tags.Name
    }
  }

  # Define automatic rollback
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}