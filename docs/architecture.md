# Multi-Agent AI Architecture

This document describes the architecture of the multi-agent AI system implemented in this Terraform blueprint.

## Architecture Diagram

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                                                                               │
│                            AWS Step Functions Workflow                         │
│                                                                               │
└───────────┬───────────────────────┬────────────────────────┬─────────────────┘
            │                       │                        │
            ▼                       ▼                        ▼
┌───────────────────┐    ┌────────────────┐      ┌────────────────────┐
│                   │    │                │      │                    │
│  Supervisor Agent │    │  Agent Router  │      │    Child Agents    │
│   (Bedrock Agent) │    │    (Lambda)    │      │  (Bedrock Agents)  │
│                   │    │                │      │                    │
└─────────┬─────────┘    └────────┬───────┘      └──────────┬─────────┘
          │                       │                         │
          │                       ▼                         │
          │              ┌────────────────┐                 │
          │              │                │                 │
          └──────────────►  Agent State   ◄─────────────────┘
                         │   (DynamoDB)   │
                         │                │
                         └────────┬───────┘
                                  │
                                  ▼
                         ┌────────────────┐
                         │                │
                         │ Knowledge Base │
                         │  (Optional)    │
                         │                │
                         └────────────────┘
```

## Component Descriptions

### 1. AWS Step Functions Workflow

The Step Functions state machine orchestrates the entire multi-agent workflow:

1. Receives the initial user request
2. Invokes the supervisor agent to analyze the request
3. Calls the agent router Lambda to determine which child agent to use
4. Saves the conversation state to DynamoDB
5. Invokes the selected child agent to process the request
6. Returns to the supervisor agent for final response formatting
7. Returns the final response to the user

### 2. Supervisor Agent (Amazon Bedrock Agent)

The supervisor agent is responsible for:

- Initial analysis of user requests
- Determining which specialized child agent should handle the request
- Providing context when delegating tasks
- Formatting final responses for consistency

### 3. Agent Router (AWS Lambda)

The agent router Lambda function:

- Extracts the supervisor's recommendation for which agent to use
- Maps the recommendation to a specific child agent
- Formats the prompt for the child agent with relevant context
- Saves conversation context to DynamoDB

### 4. Child Agents (Amazon Bedrock Agents)

Each child agent is specialized in a particular domain:

- Data Analysis: Analyzes data and provides insights
- Code Generation: Writes and explains code
- Infrastructure Planning: Designs AWS architecture solutions
- (Additional agents can be added as needed)

### 5. Agent State (Amazon DynamoDB)

The DynamoDB table stores:

- Conversation history
- Agent selection decisions
- Context for future interactions
- Session information

### 6. Knowledge Base (Optional)

The optional knowledge base provides:

- Domain-specific information for agents
- Reference materials
- Examples and templates

## Data Flow

1. **User Request**:
   - User sends a request to the Step Functions workflow

2. **Initial Analysis**:
   - Supervisor agent analyzes the request
   - Determines which child agent should handle it

3. **Agent Selection**:
   - Agent router Lambda extracts the supervisor's recommendation
   - Maps to a specific child agent
   - Formats the prompt with context

4. **State Management**:
   - Conversation state is saved to DynamoDB

5. **Task Processing**:
   - Selected child agent processes the request
   - Generates a specialized response

6. **Response Formatting**:
   - Supervisor agent formats the child agent's response
   - Ensures consistency and quality

7. **Final Response**:
   - Formatted response is returned to the user

## Security Considerations

- IAM roles with least privilege principles
- Secure API invocations
- Data encryption at rest and in transit
- Session management and authentication

## Scaling Considerations

- DynamoDB auto-scaling for state management
- Lambda concurrency for the agent router
- Step Functions capacity for orchestration
- Bedrock model throughput limits
