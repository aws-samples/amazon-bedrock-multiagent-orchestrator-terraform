/**
 * Agent Router Lambda Function
 * 
 * This function determines which child agent should handle a request based on
 * the supervisor agent's analysis and prepares the appropriate context.
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  console.log('Event received:', JSON.stringify(event, null, 2));
  
  const { supervisorResponse, sessionId, userInput } = event;
  const childAgents = JSON.parse(process.env.CHILD_AGENTS || '{}');
  
  // Extract the supervisor's recommendation for which agent to use
  // This assumes the supervisor's response includes a specific format to indicate the agent
  const agentRecommendation = extractAgentRecommendation(supervisorResponse.completion);
  
  // Determine which child agent to use based on the supervisor's recommendation
  const selectedAgentIndex = determineChildAgent(agentRecommendation, Object.keys(childAgents).length);
  const selectedAgentId = childAgents[selectedAgentIndex];
  
  if (!selectedAgentId) {
    throw new Error(`No agent found for index ${selectedAgentIndex}`);
  }
  
  // Format the prompt for the child agent with relevant context
  const formattedPrompt = formatPromptForChildAgent(
    userInput,
    supervisorResponse.completion,
    agentRecommendation
  );
  
  // Save conversation context to DynamoDB for future reference
  await saveConversationContext(sessionId, {
    userInput,
    supervisorResponse: supervisorResponse.completion,
    selectedAgentIndex,
    selectedAgentId,
    timestamp: new Date().toISOString()
  });
  
  return {
    selectedAgentId,
    selectedAgentIndex,
    formattedPrompt,
    originalQuery: userInput
  };
};

/**
 * Extract the agent recommendation from the supervisor's response
 */
function extractAgentRecommendation(supervisorResponse) {
  // This is a simplified implementation
  // In a real-world scenario, you would implement more robust parsing
  
  // Look for patterns like "I recommend the Data Analysis agent" or "Use agent: Code Generation"
  const agentTypes = ['Data Analysis', 'Code Generation', 'Infrastructure Planning'];
  
  for (const agentType of agentTypes) {
    if (supervisorResponse.includes(agentType)) {
      return agentType;
    }
  }
  
  // Default to the first agent if no clear recommendation
  return 'Data Analysis';
}

/**
 * Determine which child agent to use based on the recommendation
 */
function determineChildAgent(recommendation, agentCount) {
  // Map the recommendation to an agent index
  const agentMappings = {
    'Data Analysis': 0,
    'Code Generation': 1,
    'Infrastructure Planning': 2
  };
  
  const agentIndex = agentMappings[recommendation];
  
  // Ensure the index is valid
  if (agentIndex !== undefined && agentIndex < agentCount) {
    return agentIndex;
  }
  
  // Default to the first agent
  return 0;
}

/**
 * Format the prompt for the child agent with relevant context
 */
function formatPromptForChildAgent(userInput, supervisorResponse, agentRecommendation) {
  return `
You are a specialized agent focused on ${agentRecommendation}.

The user's original request was: "${userInput}"

The supervisor agent has analyzed this request and determined that you should handle it.
The supervisor provided this context: "${supervisorResponse}"

Please address the user's request with your specialized expertise in ${agentRecommendation}.
  `.trim();
}

/**
 * Save conversation context to DynamoDB
 */
async function saveConversationContext(sessionId, context) {
  const params = {
    TableName: process.env.STATE_TABLE,
    Item: {
      SessionId: sessionId,
      ConversationContext: context,
      LastUpdated: new Date().toISOString(),
      ExpirationTime: Math.floor(Date.now() / 1000) + 86400 // 24 hours TTL
    }
  };
  
  try {
    await dynamodb.put(params).promise();
    console.log('Saved conversation context to DynamoDB');
  } catch (error) {
    console.error('Error saving to DynamoDB:', error);
    // Continue execution even if saving fails
  }
}
