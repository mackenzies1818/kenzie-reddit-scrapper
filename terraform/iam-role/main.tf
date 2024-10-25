#create a policy to allow the user to assume the role
resource "aws_iam_role" "terraform_role" {
  name = "terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": var.aws_user_arn
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "assume_role_policy" {
  name = "AllowAssumeRole"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = var.aws_role_arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "assume_role_attachment" {
  user       = var.aws_user
  policy_arn = aws_iam_policy.assume_role_policy.arn
}

resource "aws_iam_policy" "iam_policy" {
  name = "kinesis-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords",
          "kinesis:GetRecords",
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:DescribeStreamConsumer",
          "kinesis:ListTagsForStream",
          "kinesis:RegisterStreamConsumer",
          "kinesis:DeleteStream",
          "kinesis:CreateStream",
          "kinesis:StartStreamEncryption",
          "kinesis:StopStreamEncryption",
          "kinesis:IncreaseStreamRetentionPeriod",
          "kinesis:DeregisterStreamConsumer"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListResourceTags",
          "kms:ScheduleKeyDeletion",
          "kms:CreateKey"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:CreateBucket",
          "s3:ListBucket",
          "s3:HeadBucket",
          "s3:GetObject",
          "s3:GetBucketPolicy",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketWebsite",
          "s3:GetBucketVersioning",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketLogging",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketTagging",
          "s3:DeleteBucket",
          "s3:PutObject",
          "s3:GetObjectTagging",
          "s3:DeleteObject"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:CreatePolicy",
          "iam:CreateRole",
          "iam:GetPolicy",
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:GetPolicyVersion",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListPolicyVersions",
          "iam:DeleteRole",
          "iam:DeletePolicy",
          "iam:AttachRolePolicy",
          "iam:PassRole",
          "iam:CreatePolicyVersion",
          "iam:CreateInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:DetachRolePolicy",
          "iam:RemoveRoleFromInstanceProfile"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:CreateFunction",
          "lambda:GetFunction",
          "lambda:ListVersionsByFunction",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:DeleteFunction",
          "lambda:CreateEventSourceMapping",
          "lambda:AddPermission",
          "lambda:GetPolicy",
          "lambda:GetEventSourceMapping",
          "lambda:ListTags",
          "lambda:RemovePermission",
          "lambda:DeleteEventSourceMapping",
          "lambda:UpdateFunctionConfiguration",
          "lambda:PublishVersion"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ses:VerifyEmailIdentity",
          "ses:GetIdentityVerificationAttributes",
          "ses:DeleteIdentity"
        ],
        Resource = "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:CreateKeyPair",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:CreateTags",
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstanceCreditSpecifications",
          "ec2:TerminateInstances"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kinesis_policy_attachment" {
  role       = "terraform-role"
  policy_arn = aws_iam_policy.iam_policy.arn
}

output "role_arn" {
  value = aws_iam_role.terraform_role.arn
}


