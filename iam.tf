/**
 * # IAM Configuration for Multi-Agent AI Blueprint
 *
 * IAM roles and policies for the supervisor-child agent architecture.
 */

# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for Bedrock Agents
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "agent_role" {
  count = var.create_iam_roles ? 1 : 0
  
  name = "${var.name_prefix}-agent-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_policy" "agent_policy" {
  count = var.create_iam_roles ? 1 : 0
  
  name        = "${var.name_prefix}-agent-policy"
  description = "Policy for Bedrock agents to access required resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeAgent"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.agent_state.arn
      },
      {
        Action = [
          "lambda:InvokeFunction"
        ]
        Effect   = "Allow"
        Resource = aws_lambda_function.agent_router.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "agent_policy_attachment" {
  count = var.create_iam_roles ? 1 : 0
  
  role       = aws_iam_role.agent_role[0].name
  policy_arn = aws_iam_policy.agent_policy[0].arn
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for Lambda Functions
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_prefix}-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.name_prefix}-lambda-policy"
  description = "Policy for Lambda functions in the multi-agent system"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "bedrock:InvokeAgent",
          "bedrock:InvokeModel"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.agent_state.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for Step Functions
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "step_function_role" {
  name = "${var.name_prefix}-step-function-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_policy" "step_function_policy" {
  name        = "${var.name_prefix}-step-function-policy"
  description = "Policy for Step Functions in the multi-agent system"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction"
        ]
        Effect   = "Allow"
        Resource = aws_lambda_function.agent_router.arn
      },
      {
        Action = [
          "bedrock:InvokeAgent"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.agent_state.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_function_policy_attachment" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_policy.arn
}
