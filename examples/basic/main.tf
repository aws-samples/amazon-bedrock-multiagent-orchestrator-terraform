/**
 * # Basic Multi-Agent AI Example
 *
 * This example demonstrates a basic implementation of the multi-agent AI blueprint.
 */

provider "aws" {
  region = "us-east-1"
}

module "multi_agent_ai" {
  source = "../../"
  
  name_prefix = "demo-ai-system"
  environment = "dev"
  
  # Use default supervisor and child agent configurations
  
  tags = {
    Project = "AI Demo"
    Owner   = "DevTeam"
  }
}
