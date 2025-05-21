# Using the Multi-Agent AI Blueprint

This document provides guidance on how to use the Multi-Agent AI Blueprint with a supervisor-child architecture.

## Addressing Provider Version Issues

If you encounter errors related to missing resource types like `aws_bedrock_agent`, you need to update your AWS provider version:

1. Update the `versions.tf` file to require AWS provider version 5.31.0 or later:

```hcl
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.31.0"  # Minimum version with Bedrock support
    }
  }
}
```

2. Run `terraform init -upgrade` to update the provider.

## Adding a User Interface

The blueprint doesn't include a UI by default. To add one, consider these options:

### 1. API Gateway + Web Frontend

```hcl
# API Gateway for frontend access
resource "aws_api_gateway_rest_api" "agent_api" {
  name        = "${var.name_prefix}-api"
  description = "API for multi-agent system"
}

resource "aws_api_gateway_resource" "chat_resource" {
  rest_api_id = aws_api_gateway_rest_api.agent_api.id
  parent_id   = aws_api_gateway_rest_api.agent_api.root_resource_id
  path_part   = "chat"
}

resource "aws_api_gateway_method" "chat_post" {
  rest_api_id   = aws_api_gateway_rest_api.agent_api.id
  resource_id   = aws_api_gateway_resource.chat_resource.id
  http_method   = "POST"
  authorization_type = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# Integration with Step Functions
resource "aws_api_gateway_integration" "step_functions_integration" {
  rest_api_id = aws_api_gateway_rest_api.agent_api.id
  resource_id = aws_api_gateway_resource.chat_resource.id
  http_method = aws_api_gateway_method.chat_post.http_method
  
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:states:action/StartExecution"
  
  # Request mapping template
  request_templates = {
    "application/json" = <<EOF
{
  "input": "$util.escapeJavaScript($input.body)",
  "stateMachineArn": "${aws_sfn_state_machine.agent_orchestrator.arn}"
}
EOF
  }
}

# Frontend hosting on S3/CloudFront
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.name_prefix}-frontend"
}

resource "aws_cloudfront_distribution" "frontend_distribution" {
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3Origin"
  }
  
  # CloudFront configuration...
}
```

### 2. AWS Amplify Integration

For a more managed approach, consider using AWS Amplify to host your frontend and connect to your multi-agent system.

### 3. Direct API Integration

For integration with existing applications, use the Step Functions API directly:

```javascript
// Example JavaScript code to interact with the multi-agent system
const AWS = require('aws-sdk');
const stepfunctions = new AWS.StepFunctions();

async function askMultiAgentSystem(userInput) {
  const params = {
    stateMachineArn: 'YOUR_STATE_MACHINE_ARN',
    input: JSON.stringify({
      sessionId: `session-${Date.now()}`,
      userInput: userInput
    })
  };
  
  const execution = await stepfunctions.startExecution(params).promise();
  
  // For synchronous responses, you'd need to poll for the execution result
  return execution;
}
```

## Monitoring and Debugging

Add CloudWatch Dashboards to monitor your multi-agent system:

```hcl
resource "aws_cloudwatch_dashboard" "agent_dashboard" {
  dashboard_name = "${var.name_prefix}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/States", "ExecutionsStarted", "StateMachineArn", aws_sfn_state_machine.agent_orchestrator.arn],
            ["AWS/States", "ExecutionsSucceeded", "StateMachineArn", aws_sfn_state_machine.agent_orchestrator.arn],
            ["AWS/States", "ExecutionsFailed", "StateMachineArn", aws_sfn_state_machine.agent_orchestrator.arn]
          ],
          period = 300,
          stat   = "Sum",
          region = var.aws_region,
          title  = "Step Functions Executions"
        }
      },
      {
        type = "metric",
        x    = 0,
        y    = 6,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.agent_router.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.agent_router.function_name]
          ],
          period = 300,
          stat   = "Sum",
          region = var.aws_region,
          title  = "Lambda Invocations"
        }
      }
    ]
  })
}
