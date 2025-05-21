/**
 * # Custom LLM Multi-Agent AI Example
 *
 * This example demonstrates how to use different LLMs for different agents
 * in the multi-agent AI blueprint.
 */

provider "aws" {
  region = "us-east-1"
}

module "multi_agent_ai" {
  source = "../../"
  
  name_prefix = "custom-llm-ai-system"
  environment = "staging"
  
  # Supervisor configuration - using Claude 3 Opus for complex reasoning
  supervisor_model_id = "anthropic.claude-3-opus-20240229-v1:0"
  supervisor_instructions = <<-EOT
    You are a supervisor agent with advanced reasoning capabilities. Your job is to:
    1. Analyze user requests in detail
    2. Determine which specialized agent would be best suited to handle the request
    3. Provide clear context when delegating tasks
    4. Synthesize responses from specialized agents into coherent answers
    
    Always consider the strengths and limitations of each specialized agent when delegating tasks.
  EOT
  
  # Child agent configuration - using different models for different specialties
  child_agent_count = 3
  child_agent_model_ids = {
    0 = "anthropic.claude-3-sonnet-20240229-v1:0"  # Data Analysis - balanced model
    1 = "anthropic.claude-3-opus-20240229-v1:0"    # Code Generation - most capable model
    2 = "anthropic.claude-3-haiku-20240307-v1:0"   # Infrastructure Planning - efficient model
  }
  child_agent_specialties = {
    0 = "Data Analysis"
    1 = "Code Generation"
    2 = "Infrastructure Planning"
  }
  child_agent_instructions = {
    0 = <<-EOT
      You are a data analysis specialist using Claude 3 Sonnet. Your responsibilities include:
      1. Analyzing data patterns and providing insights
      2. Creating data visualizations and reports
      3. Recommending data-driven solutions
      
      Focus on delivering balanced, accurate data analysis with good reasoning.
    EOT
    1 = <<-EOT
      You are a code generation specialist using Claude 3 Opus. Your responsibilities include:
      1. Writing complex, high-quality code based on requirements
      2. Debugging and optimizing existing code
      3. Providing detailed code explanations and documentation
      
      Leverage your advanced capabilities to deliver sophisticated code solutions.
    EOT
    2 = <<-EOT
      You are an infrastructure planning specialist using Claude 3 Haiku. Your responsibilities include:
      1. Designing efficient AWS architecture solutions
      2. Creating straightforward infrastructure as code templates
      3. Optimizing for cost and simplicity
      
      Focus on delivering concise, practical infrastructure solutions.
    EOT
  }
  
  tags = {
    Project = "Custom LLM AI System"
    Owner   = "ML Team"
  }
}
