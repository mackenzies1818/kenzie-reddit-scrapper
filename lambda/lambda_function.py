import boto3
import os
import json

sqs = boto3.client("sqs")
ses = boto3.client("ses")

SQS_URL = os.getenv("SQS_URL")
SES_EMAIL = os.getenv("SES_EMAIL")

def lambda_handler(event, context):
    for record in event["Records"]:
        message_body = record["body"]

        # Send email via SES
        response = ses.send_email(
            Source=SES_EMAIL,
            Destination={
                "ToAddresses": [SES_EMAIL]  # Change to actual recipient
            },
            Message={
                "Subject": {
                    "Data": "New SQS Message"
                },
                "Body": {
                    "Text": {
                        "Data": message_body
                    }
                }
            }
        )

        print(f"Email sent: {response}")

    return {"statusCode": 200, "body": json.dumps("Messages processed successfully")}
