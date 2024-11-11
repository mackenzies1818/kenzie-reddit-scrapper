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
QUEUE_NAME="kenzie_reddit_queue"
SNS_TOPIC="kenzie_reddit_sns_topic"

# Configure an sqs queue
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name $QUEUE_NAME
echo "Queue $QUEUE_NAME is now created!"
# Configure an sns topic
aws --endpoint-url=http://localhost:4566 sns create-topic --name $SNS_TOPIC
echo "Topic $SNS_TOPIC is now created!"

aws --endpoint-url=http://localhost:4566 sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:$SNS_TOPIC \
    --protocol sqs \
    --notification-endpoint arn:aws:sqs:us-east-1:000000000000:$QUEUE_NAME

done