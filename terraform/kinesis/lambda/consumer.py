import boto3
import json
import base64

# Initialize the SES client
ses_client = boto3.client('ses', region_name='us-east-1')

# Define the email addresses
SENDER_EMAIL = 'mackenzielsheridan+sender@gmail.com'
RECIPIENT_EMAIL = 'mackenzielsheridan+recipient@gmail.com'

def send_email(subject, body):
    response = ses_client.send_email(
        Source=SENDER_EMAIL,
        Destination={
            'ToAddresses': [RECIPIENT_EMAIL]
        },
        Message={
            'Subject': {
                'Data': subject,
            },
            'Body': {
                'Text': {
                    'Data': body,
                },
            },
        }
    )
    return response

def lambda_handler(event, context):
    print(f"in lambda handler")
    print(f"received request to trigger lambda with event: {event}")
    for record in event['Records']:
        payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
        data = json.loads(payload)

        subject = data.get('subject', 'Kenzie Email')
        body = data.get('body', 'TODO Body')
        print(f"sending email")
        response = send_email(subject, body)
        print(f"Email sent! Response: {response}")

    return {
        'statusCode': 200,
        'body': json.dumps('Emails processed successfully!')
    }
