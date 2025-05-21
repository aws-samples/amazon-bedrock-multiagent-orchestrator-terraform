{
  "Comment": "Multi-Agent Orchestration Workflow",
  "StartAt": "ProcessInitialRequest",
  "States": {
    "ProcessInitialRequest": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${lambda_router_arn}",
        "Payload": {
          "sessionId.$": "$.sessionId",
          "userInput.$": "$.userInput",
          "agentId": "${supervisor_agent_id}",
          "isInitialRequest": true
        }
      },
      "ResultPath": "$.supervisorResponse",
      "Next": "DetermineNextAgent"
    },
    "DetermineNextAgent": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${lambda_router_arn}",
        "Payload": {
          "supervisorResponse.$": "$.supervisorResponse",
          "sessionId.$": "$.sessionId",
          "userInput.$": "$.userInput"
        }
      },
      "ResultPath": "$.routerResult",
      "Next": "SaveState"
    },
    "SaveState": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:putItem",
      "Parameters": {
        "TableName": "${dynamodb_table_name}",
        "Item": {
          "SessionId": {
            "S.$": "$.sessionId"
          },
          "ConversationState": {
            "S.$": "States.JsonToString($.routerResult.Payload)"
          },
          "LastUpdated": {
            "S.$": "$$.State.EnteredTime"
          },
          "ExpirationTime": {
            "N": "86400"
          }
        }
      },
      "Next": "InvokeChildAgent"
    },
    "InvokeChildAgent": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${lambda_router_arn}",
        "Payload": {
          "sessionId.$": "$.sessionId",
          "userInput.$": "$.routerResult.Payload.formattedPrompt",
          "agentId.$": "$.routerResult.Payload.selectedAgentId",
          "isChildAgent": true
        }
      },
      "ResultPath": "$.childResponse",
      "Next": "FormatFinalResponse"
    },
    "FormatFinalResponse": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${lambda_router_arn}",
        "Payload": {
          "sessionId.$": "$.sessionId",
          "userInput.$": "States.Format('Please format and present this response from the child agent to the user: {}', $.childResponse.Payload.response)",
          "agentId": "${supervisor_agent_id}",
          "isFormatting": true
        }
      },
      "ResultPath": "$.finalResponse",
      "End": true
    }
  }
}
