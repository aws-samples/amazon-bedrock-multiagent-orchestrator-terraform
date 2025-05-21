/**
 * # Multi-Agent AI Blueprint with Supervisor-Child Architecture
 *
 * This Terraform module creates a multi-agent AI system using Amazon Bedrock
 * with a supervisor agent that handles initial interactions and delegates to
 * specialized child agents.
 */

# ---------------------------------------------------------------------------------------------------------------------
# AWS Provider Configuration
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# Local Variables
# ---------------------------------------------------------------------------------------------------------------------
locals {
  supervisor_name = "${var.name_prefix}-supervisor"
  child_agents    = { for i in range(var.child_agent_count) : i => "${var.name_prefix}-child-${i + 1}" }
  
  # Tags applied to all resources
  common_tags = merge(
    var.tags,
    {
      Project     = var.name_prefix
      Environment = var.environment
      Terraform   = "true"
    }
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# Supervisor Agent
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_bedrockagent_agent" "supervisor" {
  agent_name        = local.supervisor_name
  agent_resource_role_arn = var.create_iam_roles ? aws_iam_role.agent_role[0].arn : var.existing_agent_role_arn
  
  instruction = var.supervisor_instructions
  
  foundation_model = var.supervisor_model_id
  
  description = "Supervisor agent that handles initial interactions and delegates to specialized child agents"
  
  tags = merge(
    local.common_tags,
    {
      AgentType = "Supervisor"
    }
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# Child Agents
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_bedrockagent_agent" "child_agents" {
  for_each = local.child_agents
  
  agent_name        = each.value
  agent_resource_role_arn = var.create_iam_roles ? aws_iam_role.agent_role[0].arn : var.existing_agent_role_arn
  
  instruction = var.child_agent_instructions[each.key]
  
  foundation_model = var.child_agent_model_ids[each.key]
  
  description = "Child agent ${each.key + 1} specialized in ${var.child_agent_specialties[each.key]}"
  
  tags = merge(
    local.common_tags,
    {
      AgentType = "Child"
      Specialty = var.child_agent_specialties[each.key]
    }
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# Agent Orchestration - Step Functions
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_sfn_state_machine" "agent_orchestrator" {
  name     = "${var.name_prefix}-orchestrator"
  role_arn = aws_iam_role.step_function_role.arn
  
  definition = templatefile("${path.module}/templates/orchestration.json.tpl", {
    supervisor_agent_id = aws_bedrockagent_agent.supervisor.id
    child_agents        = jsonencode({ for k, v in aws_bedrockagent_agent.child_agents : k => v.id })
    lambda_router_arn   = aws_lambda_function.agent_router.arn
    dynamodb_table_name = aws_dynamodb_table.agent_state.name
  })
  
  tags = local.common_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Agent Router Lambda - Determines which child agent to invoke
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_function" "agent_router" {
  function_name    = "${var.name_prefix}-agent-router"
  filename         = "${path.module}/lambda/agent_router.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/agent_router.zip")
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 30
  
  environment {
    variables = {
      CHILD_AGENTS = jsonencode({ for k, v in aws_bedrockagent_agent.child_agents : k => v.id })
      STATE_TABLE  = aws_dynamodb_table.agent_state.name
    }
  }
  
  tags = local.common_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# State Management - DynamoDB
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_dynamodb_table" "agent_state" {
  name         = "${var.name_prefix}-agent-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionId"
  
  attribute {
    name = "SessionId"
    type = "S"
  }
  
  ttl {
    attribute_name = "ExpirationTime"
    enabled        = true
  }
  
  tags = local.common_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Knowledge Base (Optional)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "knowledge_base_role" {
  count = var.create_knowledge_base ? 1 : 0
  
  name = "${var.name_prefix}-kb-role"
  
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

resource "aws_iam_policy" "knowledge_base_policy" {
  count = var.create_knowledge_base ? 1 : 0
  
  name        = "${var.name_prefix}-kb-policy"
  description = "Policy for Bedrock knowledge base"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "aoss:APIAccessAll"
        ]
        Effect   = "Allow"
        Resource = aws_opensearchserverless_collection.kb_collection[0].arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "knowledge_base_policy_attachment" {
  count = var.create_knowledge_base ? 1 : 0
  
  role       = aws_iam_role.knowledge_base_role[0].name
  policy_arn = aws_iam_policy.knowledge_base_policy[0].arn
}

resource "aws_bedrockagent_knowledge_base" "agent_kb" {
  count = var.create_knowledge_base ? 1 : 0
  
  name        = "${var.name_prefix}-knowledge-base"
  description = "Knowledge base for the multi-agent system"
  role_arn    = aws_iam_role.knowledge_base_role[0].arn
  
  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.titan-embed-text-v1"
    }
  }
  
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn = aws_opensearchserverless_collection.kb_collection[0].arn
      vector_index_name = "${var.name_prefix}-vector-index"
      field_mapping {
        text_field   = "text"
        metadata_field = "metadata"
      }
    }
  }
  
  tags = local.common_tags
}

resource "aws_opensearchserverless_collection" "kb_collection" {
  count = var.create_knowledge_base ? 1 : 0
  
  name = "${var.name_prefix}-kb-collection"
  type = "VECTORSEARCH"
  
  tags = local.common_tags
}
