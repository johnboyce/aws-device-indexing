output "sns_topic_arn" {
  description = "The ARN of the SNS topic for notifications"
  value       = aws_sns_topic.device_notifications.arn
}

output "api_gateway_url" {
  description = "The invoke URL for the API Gateway"
  value       = aws_api_gateway_deployment.device_api.invoke_url
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table storing device mappings"
  value       = aws_dynamodb_table.device_mapping.name
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.device_service.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.device_service.arn
}

output "cloudwatch_event_rule" {
  description = "The name of the CloudWatch Event Rule for checking device status"
  value       = aws_cloudwatch_event_rule.device_checker.name
}
