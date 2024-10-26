import praw
import json
from dotenv import load_dotenv
import os
import boto3
import botocore.exceptions
import logging

logging.basicConfig(level=logging.INFO)
# Define the default environment to 'test' if not explicitly set
environment = os.getenv('ENV', '.env.test')

# Load the corresponding .env file based on the environment
if environment == 'prod':
    #ENV=prod python3 producer/producer.py
    load_dotenv('.env')
else:
    load_dotenv('.env.test')


logging.info(f"Running in {environment} mode")

client_secret = os.getenv('REDDIT_CLIENT_SECRET')
client_id = os.getenv('REDDIT_CLIENT_ID')
reddit_username = os.getenv('REDDIT_USERNAME')
reddit_password = os.getenv('REDDIT_PASSWORD')
reddit_useragent = os.getenv('REDDIT_USER_AGENT')
aws_region=os.getenv('AWS_REGION')
aws_endpoint=os.getenv('AWS_ENDPOINT')
kinesis_stream_name=os.getenv('AWS_KINESIS_STREAM_NAME')

# Initialize the Reddit API client
reddit = praw.Reddit(
    client_id=client_id,
    client_secret=client_secret,
    user_agent=reddit_useragent,
    username=reddit_username,
    password=reddit_password
)


# AWS Kinesis setup
kinesis = boto3.client(
    "kinesis",
    region_name=aws_region,
    endpoint_url=aws_endpoint,  # LocalStack endpoint
)
# Define your keywords
keywords = ["fifth metatarsal", "avulsion fracture", "displaced"]

# Function to check if any keyword is present in the text
def contains_keyword(text, keywords):
    return any(keyword.lower() in text.lower() for keyword in keywords)

def send_to_kinesis(data):
    print(f"sending to Kinesis: {data}")
    try:
    # Attempt to put the record into Kinesis
        response = kinesis.put_record(
            StreamName=kinesis_stream_name,
            Data=json.dumps(data),
            PartitionKey="kenzie-test" #TODO: Choose appropriate partition key
        )
        logging.info(f"Successfully put record: {response}")
        return response  # Optionally return the response
    #TODO: add better error handling?
    except botocore.exceptions.ClientError as e:
        # Handle specific client errors
        error_code = e.response['Error']['Code']
        logging.info(f"Error occurred: {error_code} - {e}")

    except Exception as e:
        logging.info(f"An unexpected error occurred: {e}")

    logging.info("Failed to send record after retries.")
    return None  # Optionally return None if failed

# Fetch posts and send to Kinesis
subreddit = reddit.subreddit('brokenbones')
for submission in subreddit.stream.submissions():
    if contains_keyword(submission.title, keywords):
        data = {
            "title": submission.title,
            "upvotes": submission.score,
            "url": submission.url
        }
        send_to_kinesis(data)
        logging.info(f"Sent to Kinesis: {data}")



