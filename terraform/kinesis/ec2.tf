resource "aws_iam_role" "ec2_kinesis_role" {
  name = "EC2KinesisRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_policy" "kinesis_policy" {
  name        = "KinesisPolicy"
  description = "Policy to allow Kinesis actions"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords",
          "kinesis:DescribeStream",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
        ]
        Resource = aws_kinesis_stream.kenzie.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_kinesis_policy" {
  policy_arn = aws_iam_policy.kinesis_policy.arn
  role       = aws_iam_role.ec2_kinesis_role.name
}

resource "aws_iam_instance_profile" "ec2_kinesis_profile" {
  name = "EC2KinesisInstanceProfile"
  role = aws_iam_role.ec2_kinesis_role.name
}

resource "aws_iam_role_policy_attachment" "attach_ecr_access" {
  role       = aws_iam_role.ec2_kinesis_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "attach_ssm_ec2_access" {
  role       = aws_iam_role.ec2_kinesis_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "kms_access_policy" {
  name        = "KMSAccessPolicy"
  description = "Allows EC2 instance to use KMS for Kinesis stream encryption"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource": aws_kms_key.kinesis_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_kms_access_policy" {
  role       = aws_iam_role.ec2_kinesis_role.name
  policy_arn = aws_iam_policy.kms_access_policy.arn
}



# Create a security group that allows SSH and HTTP traffic
resource "aws_security_group" "allow_ssh_http" {
  name = "allow_ssh_http"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the EC2 instance

resource "aws_instance" "kinesis_docker_server" {
  ami           = "ami-0ddc798b3f1a5117e"
  instance_type = "t2.micro"

  # Attach the security group and IAM role
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_kinesis_profile.name

  key_name = "kenzie_key_pair"

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker aws-cli
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user

    # Wait for Docker to start
    sleep 10

    # Authenticate Docker to ECR
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 992382748278.dkr.ecr.us-east-1.amazonaws.com

    # Pull and run Docker container
    docker pull 992382748278.dkr.ecr.us-east-1.amazonaws.com/kenzie_ecr_repo:oct-26-1
    docker run -d -p 80:80 992382748278.dkr.ecr.us-east-1.amazonaws.com/kenzie_ecr_repo:oct-26-1
  EOF

  tags = {
    Name = "kinesis-producer-server"
  }
}

# Output the public IP
output "instance_public_ip" {
  value = aws_instance.kinesis_docker_server.public_ip
}
