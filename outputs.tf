/**
 * # Outputs for Multi-Agent AI Blueprint
 *
 * Output values that can be referenced by other modules or in the console.
 */

output "supervisor_agent_id" {
  description = "ID of the supervisor agent"
  value       = aws_bedrockagent_agent.supervisor.id
}

output "child_agent_ids" {
  description = "Map of child agent indices to their IDs"
  value       = { for k, v in aws_bedrockagent_agent.child_agents : k => v.id }
}

output "orchestrator_state_machine_arn" {
  description = "ARN of the Step Functions state machine orchestrating the agents"
  value       = aws_sfn_state_machine.agent_orchestrator.arn
}

output "agent_state_table_name" {
  description = "Name of the DynamoDB table storing agent state"
  value       = aws_dynamodb_table.agent_state.name
}

output "knowledge_base_id" {
  description = "ID of the knowledge base (if created)"
  value       = var.create_knowledge_base ? aws_bedrockagent_knowledge_base.agent_kb[0].id : null
}

output "invoke_instructions" {
  description = "Instructions for invoking the multi-agent system"
  value       = <<-EOT
    To invoke the multi-agent system, use the AWS Step Functions StartExecution API with the following input:
    
    {
      "sessionId": "unique-session-id",
      "userInput": "Your query or request here"
    }
    
    Example AWS CLI command:
    
    aws stepfunctions start-execution \\
      --state-machine-arn ${aws_sfn_state_machine.agent_orchestrator.arn} \\
      --input '{"sessionId": "session-123", "userInput": "Your query or request here"}'
  EOT
}
