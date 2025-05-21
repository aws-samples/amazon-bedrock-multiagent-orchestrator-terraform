/**
 * # Variables for Multi-Agent AI Blueprint
 *
 * Configuration variables for the supervisor-child agent architecture.
 */

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
  default     = "multi-agent-ai"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# Supervisor Agent Configuration
# ---------------------------------------------------------------------------------------------------------------------
variable "supervisor_model_id" {
  description = "Amazon Bedrock model ID for the supervisor agent"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "supervisor_instructions" {
  description = "Instructions for the supervisor agent"
  type        = string
  default     = <<-EOT
    You are a supervisor agent responsible for:
    1. Initial interaction with users to understand their request
    2. Determining which specialized child agent should handle the request
    3. Delegating tasks to appropriate child agents
    4. Synthesizing responses from child agents when needed
    5. Maintaining conversation context and ensuring a coherent user experience
    
    When a user request comes in, first analyze it to determine which child agent is best suited to handle it.
    Then, prepare the necessary context and delegate to that agent.
  EOT
}

# ---------------------------------------------------------------------------------------------------------------------
# Child Agent Configuration
# ---------------------------------------------------------------------------------------------------------------------
variable "child_agent_count" {
  description = "Number of child agents to create"
  type        = number
  default     = 3
}

variable "child_agent_model_ids" {
  description = "Map of child agent index to Amazon Bedrock model ID"
  type        = map(string)
  default     = {
    0 = "anthropic.claude-3-sonnet-20240229-v1:0"
    1 = "anthropic.claude-3-sonnet-20240229-v1:0"
    2 = "anthropic.claude-3-sonnet-20240229-v1:0"
  }
}

variable "child_agent_specialties" {
  description = "Map of child agent index to specialty description"
  type        = map(string)
  default     = {
    0 = "Data Analysis"
    1 = "Code Generation"
    2 = "Infrastructure Planning"
  }
}

variable "child_agent_instructions" {
  description = "Map of child agent index to instructions"
  type        = map(string)
  default     = {
    0 = <<-EOT
      You are a specialized agent focused on data analysis. Your responsibilities include:
      1. Analyzing data patterns and providing insights
      2. Creating data visualizations and reports
      3. Recommending data-driven solutions
      
      When the supervisor agent delegates a task to you, focus on delivering high-quality data analysis.
    EOT
    1 = <<-EOT
      You are a specialized agent focused on code generation. Your responsibilities include:
      1. Writing clean, efficient code based on requirements
      2. Debugging and optimizing existing code
      3. Providing code explanations and documentation
      
      When the supervisor agent delegates a task to you, focus on delivering high-quality code solutions.
    EOT
    2 = <<-EOT
      You are a specialized agent focused on infrastructure planning. Your responsibilities include:
      1. Designing AWS architecture solutions
      2. Creating infrastructure as code templates
      3. Optimizing for cost, performance, and security
      
      When the supervisor agent delegates a task to you, focus on delivering high-quality infrastructure solutions.
    EOT
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Knowledge Base Configuration
# ---------------------------------------------------------------------------------------------------------------------
variable "create_knowledge_base" {
  description = "Whether to create a knowledge base for the agents"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Configuration
# ---------------------------------------------------------------------------------------------------------------------
variable "create_iam_roles" {
  description = "Whether to create IAM roles or use existing ones"
  type        = bool
  default     = true
}

variable "existing_agent_role_arn" {
  description = "Existing IAM role ARN for Bedrock agents (if create_iam_roles is false)"
  type        = string
  default     = ""
}
