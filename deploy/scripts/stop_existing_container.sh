#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

CONTAINER_NAME="reddit_streaming_service"

# Check if the container is running
if docker ps -q -f name=${CONTAINER_NAME}; then
    echo "Stopping existing container: ${CONTAINER_NAME}"
    docker stop ${CONTAINER_NAME}
else
    echo "No running container named ${CONTAINER_NAME} found."
fi

# Remove the container if it exists
if docker ps -aq -f name=${CONTAINER_NAME}; then
    echo "Removing existing container: ${CONTAINER_NAME}"
    docker rm ${CONTAINER_NAME}
else
    echo "No container named ${CONTAINER_NAME} found to remove."
fi


