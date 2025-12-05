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

# --- 6. Hardcode .env Output Printout ---
# The deployment is complete, and the stack output variables are known.
# We will use the deployment outputs printed by CDK and format them manually
# for the user to copy.

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo "---------------------------------------------------"
echo "👇 COPY THIS INTO YOUR FRONTEND .env FILE 👇"
echo "---------------------------------------------------"

# The following variables are taken directly from your successful deployment output:
# MailShieldStack.ApiUrl = https://zau321h11g.execute-api.us-east-2.amazonaws.com/prod/
# MailShieldStack.ControllerName = MailShieldStack-Controller8614283D-3IWb3cWEPzOY
# MailShieldStack.DecisionsBucketName = mailshieldstack-decisionsbucketcc585c32-hbe0hxfzi4z8
# MailShieldStack.FeedbackAgentName = MailShieldStack-FeedbackAgentC10094E0-0t9g3fJcNn7Y
# MailShieldStack.FeedbackTableName = sender_feedback_table
# MailShieldStack.HitlTableName = sender_intel_hitl_queue

echo "# AWS Credentials"
echo "# You must replace these two lines with the keys created in the AWS Console"
echo "AWS_REGION=us-east-2"
echo "AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_HERE"
echo "AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY_HERE"
echo ""
echo "# S3 Configuration"
# Use the bucket name from the deployment output
echo "S3_DECISIONS_BUCKET=mailshieldstack-decisionsbucketcc585c32-hbe0hxfzi4z8"
echo "S3_DECISIONS_PREFIX=runs"
echo ""
echo "# DynamoDB Tables"
echo "HITL_TABLE=sender_intel_hitl_queue"
echo "FEEDBACK_TABLE=sender_feedback_table"
echo ""
echo "# Lambda Functions"
# Use the function names from the deployment output
echo "SENDER_INTEL_CONTROLLER_FUNCTION=MailShieldStack-Controller8614283D-3IWb3cWEPzOY"
echo "FEEDBACK_AGENT_FN=MailShieldStack-FeedbackAgentC10094E0-0t9g3fJcNn7Y"
echo ""
echo "# API Gateway Endpoint"
# Use the ApiUrl from the deployment output and append '/analyze'
echo "AWS_LAMBDA_ENDPOINT=https://zau321h11g.execute-api.us-east-2.amazonaws.com/prod/analyze"
echo "---------------------------------------------------"

# The script does not require the cd .. and set -e restore commands after hardcoding.
# The previous cd infra must be undone if the rest of the script continues, but
# since we are ending here, we simply comment out the final restore.
# set -e