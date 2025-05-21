#!/bin/bash

# Script to package Lambda functions for deployment

# Create directories if they don't exist
mkdir -p lambda/dist

# Package agent_router Lambda
echo "Packaging agent_router Lambda..."
cd lambda/agent_router
npm install --production
zip -r ../dist/agent_router.zip index.js node_modules package.json
cd ../..

echo "Lambda packaging complete!"
