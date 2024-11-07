#!/bin/bash

# Install jq if not already installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."
    apt-get update && apt-get install -y jq
    if [ $? -ne 0 ]; then
        echo "Failed to install jq. Exiting."
        exit 1
    fi
else
    echo "jq is already installed."
fi

# Set up LocalStack Kinesis endpoint and stream details
#TODO: see if i can fetch from .env.test file
AWS_ENDPOINT_URL="http://localhost:4566"
SES_EMAIL="mackenzielsheridan@gmail.com"
QUEUE_NAME="kenzie_reddit_queue"

# Configure a verified email in LocalStack SES
aws --endpoint-url=$AWS_ENDPOINT_URL ses verify-email-identity --email-address $SES_EMAIL
echo "Email $SES_EMAIL is now verified!"
# Configure an sqs queue
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name $QUEUE_NAME
echo "Queue $QUEUE_NAME is now created!"

done