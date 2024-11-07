from dotenv import load_dotenv
import os
import boto3
import time
import json

# Define the default environment to 'test' if not explicitly set
environment = os.getenv('ENV', '.env.test')

# Load the corresponding .env file based on the environment
if environment == 'prod':
    load_dotenv('.env')
else:
    load_dotenv('.env.test')

print(f"Running in {environment} mode")

aws_region = os.getenv('AWS_REGION')
aws_endpoint = os.getenv('AWS_ENDPOINT')
sqs_queue_url = os.getenv('AWS_SQS_QUEUE_URL')
aws_ses_verified_email = os.getenv('AWS_SES_EMAIL')
aws_ses_recipient_email = os.getenv('AWS_SES_RECIPIENT_EMAIL')

# Set up SES and SQS clients
sqs_client = boto3.client(
    "sqs",
    region_name=aws_region,
    endpoint_url=aws_endpoint  # LocalStack endpoint if used
)
ses_client = boto3.client(
    "ses",
    region_name=aws_region,
    endpoint_url=aws_endpoint  # LocalStack endpoint if used
)

def send_email(recipient_email, subject, body):
    """
    Sends an email via AWS SES
    """
    try:
        response = ses_client.send_email(
            Source=aws_ses_verified_email,
            Destination={
                'ToAddresses': [recipient_email],
            },
            Message={
                'Subject': {'Data': subject},
                'Body': {
                    'Text': {'Data': body}
                }
            }
        )
        print(f"Email sent! SES Message ID: {response['MessageId']}")
    except Exception as e:
        print(f"Error sending email: {e}")

def process_messages(messages):
    """
    Processes SQS messages and sends an email based on the content
    """
    for message in messages:
        data = message['Body']

        # Example: Parse message (assuming it's structured as JSON)
        print(f"Processing message: {data}")
        email_body = f"New message received from SQS: {data}"
        recipient_email = aws_ses_recipient_email
        subject = "New SQS Message - TEST"

        # Send email with the content from SQS message
        send_email(recipient_email, subject, email_body)

        # Delete the message from the queue after processing
        sqs_client.delete_message(
            QueueUrl=sqs_queue_url,
            ReceiptHandle=message['ReceiptHandle']
        )
        print(f"Deleted message: {message['MessageId']}")

def consume_queue():
    """
    Polls messages from the SQS queue and processes them
    """
    while True:
        # Receive messages from SQS
        response = sqs_client.receive_message(
            QueueUrl=sqs_queue_url,
            MaxNumberOfMessages=10,  # Max number allowed by SQS
            WaitTimeSeconds=10  # Long polling for efficiency
        )

        messages = response.get('Messages', [])
        if messages:
            process_messages(messages)
        else:
            print("No new messages, sleeping for 2 seconds...")

        # Sleep to avoid excessive polling
        time.sleep(2)

if __name__ == "__main__":
    consume_queue()
