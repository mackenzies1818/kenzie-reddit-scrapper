from dotenv import load_dotenv
import os
import boto3
import time
#USED FOR LOCAL TESTING ONLY
# Define the default environment to 'test' if not explicitly set
environment = os.getenv('ENV', '.env.test')

# Load the corresponding .env file based on the environment
if environment == 'prod':
    load_dotenv('.env')
else:
    load_dotenv('.env.test')


print(f"Running in {environment} mode")

aws_region=os.getenv('AWS_REGION')
aws_endpoint=os.getenv('AWS_ENDPOINT')
kinesis_stream_name=os.getenv('AWS_KINESIS_STREAM_NAME')
aws_ses_verified_email=os.getenv('AWS_SES_EMAIL')
aws_ses_recipient_email=os.getenv('AWS_SES_RECIPIENT_EMAIL')

# Set up SES and Kinesis clients
kinesis_client = boto3.client(
    "kinesis",
    region_name=aws_region,
    endpoint_url=aws_endpoint,  # LocalStack endpoint
)
ses_client = boto3.client(
    "ses",
    region_name=aws_region,
    endpoint_url=aws_endpoint,  # LocalStack endpoint
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

def process_records(records):
    """
    Processes Kinesis records and sends an email based on the content
    """
    for record in records:
        data = record['Data'].decode('utf-8')  # Kinesis records are base64 encoded

        # Example: Parse message (assuming it's structured as JSON or a string)
        print(f"Processing record: {data}")

        # TODO Customize this part based on your data format and use case
        email_body = f"New message received from Kinesis: {data}"
        recipient_email = aws_ses_recipient_email
        subject = "New Kinesis Stream Message - TEST"

        # Send email with the content from Kinesis stream
        send_email(recipient_email, subject, email_body)

def consume_stream():
    """
    Consumes records from the Kinesis stream and processes them
    """
    shard_iterator = kinesis_client.get_shard_iterator(
        StreamName=kinesis_stream_name,
        # TODO: FIGURE OUT WHAT SHARED ID SHOULD BE?
        ShardId='shardId-000000000000',  # Automate shard discovery if you have multiple shards
        ShardIteratorType='LATEST'
    )['ShardIterator']

    while True:
        # Get records from Kinesis
        response = kinesis_client.get_records(ShardIterator=shard_iterator, Limit=100)
        shard_iterator = response['NextShardIterator']
        records = response['Records']

        # Process records if there are any, otherwise sleep and wait for new records
        if records:
            process_records(records)
        else:
            print("No new records, sleeping for 2 seconds...")

        # Sleep to avoid throttling and handle intervals between fetching
        time.sleep(2)

if __name__ == "__main__":
    consume_stream()
