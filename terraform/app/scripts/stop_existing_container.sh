#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Get the name of the container to stop; replace 'my_container_name' with your actual container name
CONTAINER_NAME="reddit_streaming_service"

# Check if the container is running
if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo "Stopping existing container: ${CONTAINER_NAME}"
    docker stop ${CONTAINER_NAME}
fi

# Remove the container if it exists
if [ "$(docker ps -aq -f status=exited -f name=${CONTAINER_NAME})" ]; then
    echo "Removing existing container: ${CONTAINER_NAME}"
    docker rm ${CONTAINER_NAME}
fi


