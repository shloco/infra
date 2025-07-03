#!/bin/bash

# GitHub Actions AWS Setup Script
# This script helps set up AWS resources for GitHub Actions deployment

set -e

echo "🚀 GitHub Actions AWS Setup for CDK"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if jq is installed (needed for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is not installed. Installing it now...${NC}"
    if command -v brew &> /dev/null; then
        brew install jq
    else
        echo -e "${RED}❌ Please install jq manually: https://jqlang.github.io/jq/download/${NC}"
        echo -e "${YELLOW}On macOS: brew install jq${NC}"
        echo -e "${YELLOW}On Ubuntu/Debian: sudo apt-get install jq${NC}"
        exit 1
    fi
fi

# Check if user is logged in
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS Account ID: ${ACCOUNT_ID}${NC}"

# Prompt for GitHub repository details
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter your repository name: " REPO_NAME

echo -e "\n${YELLOW}Setting up IAM resources...${NC}"

# Create the IAM policy
POLICY_NAME="GitHubActionsCDKPolicy"
echo "Creating IAM policy: ${POLICY_NAME}"

POLICY_ARN=$(aws iam create-policy \
    --policy-name ${POLICY_NAME} \
    --policy-document file://docs/github-actions-iam-policy.json \
    --query 'Policy.Arn' \
    --output text 2>/dev/null || aws iam get-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME} --query 'Policy.Arn' --output text)

echo -e "${GREEN}✅ Policy created/exists: ${POLICY_ARN}${NC}"

# Option 1: Create IAM User (traditional approach)
echo -e "\n${YELLOW}Choose authentication method:${NC}"
echo "1) IAM User with Access Keys (simpler)"
echo "2) OIDC with IAM Role (more secure)"
read -p "Enter choice (1 or 2): " AUTH_CHOICE

if [ "$AUTH_CHOICE" = "1" ]; then
    # Create IAM user
    USER_NAME="github-actions-cdk"
    echo "Creating IAM user: ${USER_NAME}"
    
    if aws iam create-user --user-name ${USER_NAME} >/dev/null 2>&1; then
        echo -e "${GREEN}✅ IAM user created successfully${NC}"
    else
        if aws iam get-user --user-name ${USER_NAME} >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  IAM user already exists, continuing...${NC}"
        else
            echo -e "${RED}❌ Failed to create IAM user. Check your permissions.${NC}"
            exit 1
        fi
    fi
    
    # Attach policy to user
    echo "Attaching policy to user..."
    if aws iam attach-user-policy --user-name ${USER_NAME} --policy-arn ${POLICY_ARN} 2>/dev/null; then
        echo -e "${GREEN}✅ Policy attached to user${NC}"
    else
        echo -e "${YELLOW}⚠️  Policy might already be attached${NC}"
    fi
    
    echo -e "${GREEN}✅ IAM user created and policy attached${NC}"
    
    # Create access keys
    echo "Creating access keys..."
    if KEYS=$(aws iam create-access-key --user-name ${USER_NAME} --output json 2>/dev/null); then
        ACCESS_KEY=$(echo $KEYS | jq -r '.AccessKey.AccessKeyId')
        SECRET_KEY=$(echo $KEYS | jq -r '.AccessKey.SecretAccessKey')
        
        if [ "$ACCESS_KEY" = "null" ] || [ "$SECRET_KEY" = "null" ]; then
            echo -e "${RED}❌ Failed to parse access keys${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✅ Access keys created successfully${NC}"
    else
        echo -e "${RED}❌ Failed to create access keys. The user might already have 2 access keys (AWS limit).${NC}"
        echo -e "${YELLOW}💡 Try deleting old access keys first or use a different user.${NC}"
        exit 1
    fi
    
    echo -e "\n${GREEN}✅ Setup Complete!${NC}"
    echo -e "\n${YELLOW}Add these secrets to your GitHub repository:${NC}"
    echo "AWS_ACCESS_KEY_ID: ${ACCESS_KEY}"
    echo "AWS_SECRET_ACCESS_KEY: ${SECRET_KEY}"
    echo "AWS_ACCOUNT_ID: ${ACCOUNT_ID}"
    
elif [ "$AUTH_CHOICE" = "2" ]; then
    # Create OIDC provider
    echo "Creating OIDC provider..."
    if aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
        --thumbprint-list 1c58a3a8518e8759bf075b76b750d4f2df264fcd \
        >/dev/null 2>&1; then
        echo -e "${GREEN}✅ OIDC provider created${NC}"
    else
        echo -e "${YELLOW}⚠️  OIDC provider already exists or failed to create${NC}"
    fi
    
    echo "Generating trust policy..."
    
    # Create trust policy
    TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/${REPO_NAME}:*"
        }
      }
    }
  ]
}
EOF
)
    
    # Create IAM role
    ROLE_NAME="GitHubActionsCDKRole"
    echo "Creating IAM role: ${ROLE_NAME}"
    
    echo "$TRUST_POLICY" > /tmp/trust-policy.json
    
    # Try to create the role, with better error handling
    if aws iam create-role \
        --role-name ${ROLE_NAME} \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --output text >/dev/null 2>&1; then
        echo -e "${GREEN}✅ IAM role created successfully${NC}"
    else
        # Check if role already exists
        if aws iam get-role --role-name ${ROLE_NAME} >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  IAM role already exists, continuing...${NC}"
        else
            echo -e "${RED}❌ Failed to create IAM role. Check your permissions.${NC}"
            rm /tmp/trust-policy.json
            exit 1
        fi
    fi
    
    # Attach policy to role
    echo "Attaching policy to role..."
    if aws iam attach-role-policy \
        --role-name ${ROLE_NAME} \
        --policy-arn ${POLICY_ARN} 2>/dev/null; then
        echo -e "${GREEN}✅ Policy attached to role${NC}"
    else
        echo -e "${YELLOW}⚠️  Policy might already be attached${NC}"
    fi
    
    ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
    
    echo -e "\n${GREEN}✅ Setup Complete!${NC}"
    echo -e "\n${YELLOW}Add these secrets to your GitHub repository:${NC}"
    echo "AWS_ROLE_ARN: ${ROLE_ARN}"
    echo "AWS_ACCOUNT_ID: ${ACCOUNT_ID}"
    
    echo -e "\n${YELLOW}Also update your workflow to use OIDC authentication (see docs/OIDC_SETUP.md)${NC}"
    
    rm /tmp/trust-policy.json
else
    echo -e "${RED}❌ Invalid choice${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Add the secrets to your GitHub repository (Settings → Secrets and variables → Actions)"
echo "2. Create 'staging' and 'production' environments in GitHub (Settings → Environments)"
echo "3. Push your code to trigger the first workflow"
echo "4. Check the Actions tab to monitor deployments"

echo -e "\n${GREEN}🎉 GitHub Actions setup complete!${NC}"
