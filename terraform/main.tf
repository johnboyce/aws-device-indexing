provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "device_mapping" {
  name           = "DevicePhoneMapping"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "device_id"
  range_key      = "phone_number"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "phone_number"
    type = "S"
  }
}
