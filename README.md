# AWS Device Indexing

This repository contains Terraform configurations and Lambda functions for managing device-to-phone mappings in AWS.

## Features
- **DynamoDB**: Store device-to-phone mappings.
- **API Gateway**: Expose RESTful APIs.
- **Lambda Functions**: Handle business logic.
- **SNS**: Send SMS notifications.
- **GitHub Actions**: Automate deployment.

## Setup Instructions
1. Configure **AWS credentials** in GitHub Secrets.
2. Push changes to  to trigger deployment.

## Deployment
Terraform and Lambda updates are deployed automatically using GitHub Actions.
