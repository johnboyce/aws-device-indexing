provider "aws" {
  region = var.aws_region
}

resource "aws_dynamodb_table" "device_mapping" {
  name         = "DevicePhoneMapping"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "device_id"
  range_key    = "phone_number"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "phone_number"
    type = "S"
  }
}

resource "aws_sns_topic" "device_notifications" {
  name = "DeviceNotificationTopic"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_dynamodb_sns" {
  name       = "lambda_dynamodb_sns_policy"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_policy_attachment" "lambda_sns" {
  name       = "lambda_sns_policy"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_lambda_function" "device_service" {
  function_name    = "DeviceService"
  handler          = "device_service.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_role.arn
  filename         = "${path.module}/../lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda.zip")
}


resource "aws_api_gateway_rest_api" "device_api" {
  name        = "DeviceAPI"
  description = "API for managing devices and phone numbers"
}

resource "aws_api_gateway_resource" "device_resource" {
  rest_api_id = aws_api_gateway_rest_api.device_api.id
  parent_id   = aws_api_gateway_rest_api.device_api.root_resource_id
  path_part   = "device"
}

resource "aws_api_gateway_method" "device_post" {
  rest_api_id   = aws_api_gateway_rest_api.device_api.id
  resource_id   = aws_api_gateway_resource.device_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_deployment" "device_api" {
  depends_on = [
    aws_api_gateway_integration.device_post_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.device_api.id
}

resource "aws_api_gateway_stage" "device_stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.device_api.id
  deployment_id = aws_api_gateway_deployment.device_api.id
}

resource "aws_cloudwatch_event_rule" "device_checker" {
  name                = "DeviceOnlineCheck"
  description         = "Periodically checks if a device is online"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule = aws_cloudwatch_event_rule.device_checker.name
  arn  = aws_lambda_function.device_service.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.device_service.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.device_checker.arn
}

resource "aws_api_gateway_integration" "device_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.device_api.id
  resource_id = aws_api_gateway_resource.device_resource.id
  http_method = aws_api_gateway_method.device_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.device_service.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.device_service.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.device_api.execution_arn}/*/*"
}