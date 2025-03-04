import json
import boto3
import time
from datetime import datetime, timedelta

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

device_table = dynamodb.Table('DevicePhoneMapping')
sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:DeviceNotificationTopic"


def handler(event, context):
    path = event.get("pathParameters", {})
    http_method = event["httpMethod"]

    if http_method == "POST" and "device_id" in path:
        return add_phone_number(event)
    elif http_method == "GET" and "device_id" in path:
        return get_phone_numbers(event)
    return {"statusCode": 400, "body": "Invalid Request"}


def add_phone_number(event):
    body = json.loads(event["body"])
    device_id = event["pathParameters"]["device_id"]
    phone_number = body["phone_number"]

    device_table.put_item(Item={
        "device_id": device_id,
        "phone_number": phone_number,
        "timestamp": int(time.time())
    })

    return {"statusCode": 200, "body": json.dumps({"message": "Phone number added."})}


def get_phone_numbers(event):
    device_id = event["pathParameters"]["device_id"]
    response = device_table.query(KeyConditionExpression=boto3.dynamodb.conditions.Key("device_id").eq(device_id))
    phone_numbers = [item["phone_number"] for item in response.get("Items", [])]
    return {"statusCode": 200, "body": json.dumps({"phone_numbers": phone_numbers})}
