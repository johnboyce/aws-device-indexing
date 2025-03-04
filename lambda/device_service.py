import json
import boto3
import os
import logging
from botocore.exceptions import BotoCoreError, ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

table_name = os.getenv("DYNAMODB_TABLE", "DevicePhoneMapping")
topic_arn = os.getenv("SNS_TOPIC_ARN")

table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    try:
        logger.info("Received event: %s", json.dumps(event))

        http_method = event.get("httpMethod")
        path = event.get("pathParameters", {})
        body = json.loads(event.get("body", "{}"))

        if http_method == "POST" and "device_id" in body and "phone_number" in body:
            return add_device_phone_mapping(body["device_id"], body["phone_number"])

        elif http_method == "GET" and "device_id" in path:
            return get_device_phone_mappings(path["device_id"])

        else:
            return response(400, {"error": "Invalid request"})

    except json.JSONDecodeError as e:
        logger.error("JSON decoding error: %s", str(e))
        return response(400, {"error": "Invalid JSON format"})

    except Exception as e:
        logger.error("Unhandled error: %s", str(e), exc_info=True)
        return response(500, {"error": str(e)})

def add_device_phone_mapping(device_id, phone_number):
    try:
        table.put_item(Item={"device_id": device_id, "phone_number": phone_number})

        if topic_arn:
            sns.publish(TopicArn=topic_arn, Message=f"Device {device_id} is associated with {phone_number}")

        return response(201, {"message": "Mapping added successfully"})

    except (BotoCoreError, ClientError) as e:
        logger.error("DynamoDB or SNS error: %s", str(e), exc_info=True)
        return response(500, {"error": "Failed to process request"})

def get_device_phone_mappings(device_id):
    try:
        result = table.query(KeyConditionExpression="device_id = :id", ExpressionAttributeValues={":id": device_id})
        phone_numbers = [item["phone_number"] for item in result.get("Items", [])]

        return response(200, {"device_id": device_id, "phone_numbers": phone_numbers})

    except (BotoCoreError, ClientError) as e:
        logger.error("DynamoDB query error: %s", str(e), exc_info=True)
        return response(500, {"error": "Failed to fetch device mappings"})

def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }
