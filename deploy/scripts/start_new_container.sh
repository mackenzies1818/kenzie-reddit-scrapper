#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 992382748278.dkr.ecr.us-east-1.amazonaws.com

# Define the repository URI and image tag
REPO_URI="992382748278.dkr.ecr.us-east-1.amazonaws.com/kenzie_ecr_repo"
TAG="latest" # TODO use codebuild tag instead
CONTAINER_NAME="reddit_streaming_service"

# Stop and remove the existing container (if running)
docker ps -q --filter "name=reddit_streaming_service" | grep -q . && docker stop reddit_streaming_service && docker rm reddit_streaming_service

# Pull the latest Docker image
echo "Pulling the latest image from ECR: ${REPO_URI}:${TAG}"
docker pull ${REPO_URI}:${TAG}

# Run the new Docker container
echo "Starting new container: ${CONTAINER_NAME}"
docker run -d --name ${CONTAINER_NAME} -p 80:80 ${REPO_URI}:${TAG}

