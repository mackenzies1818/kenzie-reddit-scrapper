#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Define the repository URI and image tag
REPO_URI="992382748278.dkr.ecr.us-east-1.amazonaws.com/kenzie_ecr_repo"
TAG="latest"  # Change this to your desired tag if needed
CONTAINER_NAME="reddit_streaming_service"

# Pull the latest Docker image
echo "Pulling the latest image from ECR: ${REPO_URI}:${TAG}"
docker pull ${REPO_URI}:${TAG}

# Run the new Docker container
echo "Starting new container: ${CONTAINER_NAME}"
docker run -d --name ${CONTAINER_NAME} -p 80:80 ${REPO_URI}:${TAG}

