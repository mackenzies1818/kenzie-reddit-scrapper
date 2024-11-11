resource "aws_iam_role" "ec2_reddit_role" {
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


resource "aws_iam_policy" "ec2_policy" {
  name        = "SQSPolicy"
  description = "Policy to allow SQS actions"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
      ]
      Resource = aws_sqs_queue.reddit_queue.arn
      }]
  })
}

resource "aws_iam_policy" "codedeploy_ec2_policy" {
  name        = "KinesisPolicy"
  description = "Policy to allow Kinesis actions"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]},
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": [
          aws_s3_bucket.pipeline_bucket.arn,                    # Allow listing the bucket
          "${aws_s3_bucket.pipeline_bucket.arn}/*" # Allow access to all objects in the prefix
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "codedeploy:PutLifecycleEventHookExecutionStatus",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig"
        ],
        "Resource": "*"
      }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  policy_arn = aws_iam_policy.ec2_policy.arn
  role       = aws_iam_role.ec2_reddit_role.name
}
resource "aws_iam_role_policy_attachment" "attach_codedeploy_policy" {
  policy_arn = aws_iam_policy.codedeploy_ec2_policy.arn
  role       = aws_iam_role.ec2_reddit_role.name
}

resource "aws_iam_instance_profile" "ec2_reddit_profile" {
  name = "EC2RedditInstanceProfile"
  role = aws_iam_role.ec2_reddit_role.name
}

resource "aws_iam_role_policy_attachment" "attach_ecr_access" {
  role       = aws_iam_role.ec2_reddit_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "attach_ssm_ec2_access" {
  role       = aws_iam_role.ec2_reddit_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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

resource "aws_instance" "reddit_docker_server" {
  ami           = "ami-0ddc798b3f1a5117e"
  instance_type = "t2.micro"

  # Attach the security group and IAM role
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_reddit_profile.name

  key_name = "kenzie_key_pair"

  user_data = <<-EOF
    #!/bin/bash
    # Update packages
    yum update -y

    # Install Docker and AWS CLI
    yum install -y docker aws-cli

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    # Add ec2-user to Docker group
    usermod -aG docker ec2-user

    # Wait for Docker to start
    sleep 10

    # Authenticate Docker to ECR
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 992382748278.dkr.ecr.us-east-1.amazonaws.com

    # Define the repository and tag
    REPO_URI="992382748278.dkr.ecr.us-east-1.amazonaws.com/kenzie_ecr_repo"
    TAG="latest"

    # Pull the latest Docker image
    docker pull $REPO_URI:$TAG

    # Run the Docker container in detached mode, mapping port 80 of the container to port 80 of the host
    docker run -d --name "reddit_streaming_service" -p 80:80 $REPO_URI:$TAG

    # Install CodeDeploy Agent
    yum install -y ruby
    cd /home/ec2-user
    wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto

    # Start CodeDeploy agent service
    service codedeploy-agent start
  EOF

  tags = {
    Name = "kinesis-producer-server"
  }
}

# Output the public IP
output "instance_public_ip" {
  value = aws_instance.reddit_docker_server.public_ip
}
