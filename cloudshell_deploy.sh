#!/bin/bash
set -e

echo "🛡️  Starting MailShield Backend Deployment..."

# --- 1. Prepare Build Area ---
echo "📦 Preparing build directory..."
rm -rf dist
mkdir -p dist/lambdas
mkdir -p dist/config_defaults

# --- 2. Bundle Configs ---
echo "📂 Bundling default configurations..."
cp -r config_defaults/* dist/config_defaults/

# --- 3. Bundle Code ---
echo "🐍 Bundling Python Logic..."
cp -r lambdas/* dist/lambdas/
echo "📚 Installing dependencies..."
# Use an explicit python version if necessary, otherwise this is fine
pip install -r lambdas/requirements.txt -t dist/lambdas/ --quiet

# --- 4. Install CDK ---
echo "🛠️  Installing AWS CDK..."
cd infra
npm install --quiet

# --- 5. Deploy ---
echo "🚀 Deploying to AWS..."
npx cdk bootstrap
npx cdk deploy --require-approval never

# --- 6. Generate .env Output ---
# Change directory back to the root to run cdk output easily
cd ..

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo "---------------------------------------------------"
echo "👇 COPY THIS INTO YOUR FRONTEND .env FILE 👇"
echo "---------------------------------------------------"

# Detect Region safely
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-2}}"

# Fetch outputs using 'cdk output'
# Note: Output keys match the names used in your CDK stack (e.g., MailShieldStack.ApiUrl)
DECISIONS_BUCKET=$(npx cdk output MailShieldStack.DecisionsBucketName)
HITL_TABLE=$(npx cdk output MailShieldStack.HitlTableName)
FEEDBACK_TABLE=$(npx cdk output MailShieldStack.FeedbackTableName)
CONTROLLER_FN=$(npx cdk output MailShieldStack.ControllerName)
FEEDBACK_AGENT_FN=$(npx cdk output MailShieldStack.FeedbackAgentName)
# Use the simpler ApiUrl output key
API_BASE_URL=$(npx cdk output MailShieldStack.ApiUrl) 

# Construct the final endpoint
LAMBDA_ENDPOINT="${API_BASE_URL}analyze"

echo "# AWS Credentials"
echo "# You must replace these two lines with the keys created in the AWS Console"
echo "AWS_REGION=$REGION"
echo "AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_HERE"
echo "AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY_HERE"
echo ""
echo "# S3 Configuration"
echo "S3_DECISIONS_BUCKET=$DECISIONS_BUCKET"
echo "S3_DECISIONS_PREFIX=runs"
echo ""
echo "# DynamoDB Tables"
echo "HITL_TABLE=$HITL_TABLE"
echo "FEEDBACK_TABLE=$FEEDBACK_TABLE"
echo ""
echo "# Lambda Functions"
echo "SENDER_INTEL_CONTROLLER_FUNCTION=$CONTROLLER_FN"
echo "FEEDBACK_AGENT_FN=$FEEDBACK_AGENT_FN"
echo ""
echo "# API Gateway Endpoint"
echo "AWS_LAMBDA_ENDPOINT=$LAMBDA_ENDPOINT"
echo "---------------------------------------------------"

# Restore 'set -e' behavior if needed, otherwise leave it off
set -e