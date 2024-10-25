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
STREAM_NAME="kenzieRedditStream"
SES_EMAIL="mackenzielsheridan@gmail.com"

# Configure a verified email in LocalStack SES
#TODO: use env var for email
aws --endpoint-url=$AWS_ENDPOINT_URL ses verify-email-identity --email-address $SES_EMAIL
echo "Email $SES_EMAIL is now verified!"

# Create the Kinesis stream with 1 shard
echo "Creating Kinesis stream $STREAM_NAME..."
aws --endpoint-url=$AWS_ENDPOINT_URL kinesis create-stream \
    --stream-name $STREAM_NAME \
    --shard-count 1

# Wait for the stream to become ACTIVE
echo "Waiting for Kinesis stream $STREAM_NAME to become ACTIVE..."
while : ; do
    STATUS=$(aws --endpoint-url=$AWS_ENDPOINT_URL kinesis describe-stream \
        --stream-name $STREAM_NAME \
        --query 'StreamDescription.StreamStatus' \
        --output text)
    if [ "$STATUS" == "ACTIVE" ]; then
        break
    fi
    echo "Still waiting for stream to become ACTIVE..."
    sleep 1
done

echo "Stream $STREAM_NAME is active!"

#TODO: is this necessary?
# Put records into the Kinesis stream
echo "Putting records into stream $STREAM_NAME..."
for i in {0..9}; do
    DATA=$(jq -n --arg id "$i" --arg title "fifth metatarsal fracture and avulsion fracture $i" --arg url "https://www.reddit.com/gallery/1fn1w06" \
        '{title: $title, upvotes: $id, url: $url}')

    aws --endpoint-url=$AWS_ENDPOINT_URL kinesis put-record \
        --stream-name $STREAM_NAME \
        --data "$DATA" \
        --partition-key "$i"

    echo "Put record $i into stream $STREAM_NAME"
done

# Get shard ID for the stream (since there's only one shard)
SHARD_ID=$(aws --endpoint-url=$AWS_ENDPOINT_URL kinesis describe-stream \
    --stream-name $STREAM_NAME \
    --query 'StreamDescription.Shards[0].ShardId' \
    --output text)

# Get a shard iterator
SHARD_ITERATOR=$(aws --endpoint-url=$AWS_ENDPOINT_URL kinesis get-shard-iterator \
    --stream-name $STREAM_NAME \
    --shard-id $SHARD_ID \
    --shard-iterator-type TRIM_HORIZON \
    --query 'ShardIterator' \
    --output text)

# Retrieve and print records from the Kinesis stream
echo "Retrieving records from the stream..."
while : ; do
    RECORDS=$(aws --endpoint-url=$AWS_ENDPOINT_URL kinesis get-records \
        --shard-iterator $SHARD_ITERATOR \
        --limit 2 \
        --query 'Records' \
        --output json)

    if [ "$RECORDS" != "[]" ]; then
        echo "Retrieved records:"
        echo "$RECORDS" | jq -r '.[].Data | @base64d'  # Decode base64 data
    else
        echo "No more records, startup script complete."
        break
    fi

    # Get the next shard iterator
    SHARD_ITERATOR=$(aws --endpoint-url=$AWS_ENDPOINT_URL kinesis get-records \
        --shard-iterator $SHARD_ITERATOR \
        --limit 2 \
        --query 'NextShardIterator' \
        --output text)

    sleep 1  # Sleep to simulate time gap between fetches
done