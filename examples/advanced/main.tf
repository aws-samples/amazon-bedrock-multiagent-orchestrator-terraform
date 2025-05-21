/**
 * # Advanced Multi-Agent AI Example
 *
 * This example demonstrates an advanced implementation of the multi-agent AI blueprint
 * with custom agent configurations and knowledge base integration.
 */

provider "aws" {
  region = "us-west-2"
}

module "multi_agent_ai" {
  source = "../../"
  
  name_prefix = "enterprise-ai-system"
  environment = "prod"
  aws_region  = "us-west-2"
  
  # Supervisor configuration
  supervisor_model_id = "anthropic.claude-3-opus-20240229-v1:0"
  supervisor_instructions = <<-EOT
    You are an enterprise-grade supervisor agent responsible for:
    1. Understanding complex business requests
    2. Determining which specialized agent should handle each part of the request
    3. Coordinating between multiple agents when necessary
    4. Ensuring responses meet enterprise quality standards
    5. Maintaining security and compliance in all interactions
    
    When a request comes in, analyze it thoroughly and delegate appropriately.
  EOT
  
  # Child agent configuration
  child_agent_count = 4
  child_agent_model_ids = {
    0 = "anthropic.claude-3-sonnet-20240229-v1:0"  # Data Analysis
    1 = "anthropic.claude-3-opus-20240229-v1:0"    # Code Generation
    2 = "anthropic.claude-3-sonnet-20240229-v1:0"  # Infrastructure Planning
    3 = "anthropic.claude-3-haiku-20240307-v1:0"   # Customer Support
  }
  child_agent_specialties = {
    0 = "Data Analysis"
    1 = "Code Generation"
    2 = "Infrastructure Planning"
    3 = "Customer Support"
  }
  child_agent_instructions = {
    0 = <<-EOT
      You are an enterprise data analysis specialist. Your responsibilities include:
      1. Analyzing complex business data and providing actionable insights
      2. Creating professional data visualizations and reports
      3. Recommending data-driven business solutions
      4. Ensuring all analysis follows data governance standards
      
      When the supervisor delegates a task to you, deliver enterprise-grade data analysis.
    EOT
    1 = <<-EOT
      You are an enterprise code generation specialist. Your responsibilities include:
      1. Writing production-ready, secure code based on enterprise requirements
      2. Debugging and optimizing existing enterprise systems
      3. Providing comprehensive documentation following company standards
      4. Ensuring code meets security and compliance requirements
      
      When the supervisor delegates a task to you, deliver enterprise-grade code solutions.
    EOT
    2 = <<-EOT
      You are an enterprise infrastructure planning specialist. Your responsibilities include:
      1. Designing scalable, secure AWS architecture solutions
      2. Creating infrastructure as code templates following company standards
      3. Optimizing for cost, performance, security, and compliance
      4. Planning for disaster recovery and business continuity
      
      When the supervisor delegates a task to you, deliver enterprise-grade infrastructure solutions.
    EOT
    3 = <<-EOT
      You are an enterprise customer support specialist. Your responsibilities include:
      1. Addressing customer inquiries with professional, helpful responses
      2. Troubleshooting product issues and providing clear solutions
      3. Escalating complex issues to the appropriate teams
      4. Maintaining a positive customer experience throughout interactions
      
      When the supervisor delegates a task to you, deliver enterprise-grade customer support.
    EOT
  }
  
  # Enable knowledge base
  create_knowledge_base = true
  
  tags = {
    Project     = "Enterprise AI Assistant"
    Owner       = "AI Center of Excellence"
    Department  = "Technology"
    CostCenter  = "CC-12345"
    Environment = "Production"
  }
}
