#!/bin/bash

# Test AWS Credentials for GitHub Actions
echo "🔍 Testing AWS Credentials Setup"
echo "================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "\n${YELLOW}1. Testing local AWS CLI...${NC}"
if aws sts get-caller-identity >/dev/null 2>&1; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    echo -e "${GREEN}✅ Local AWS CLI working${NC}"
    echo "   Account: $ACCOUNT_ID"
    echo "   User: $USER_ARN"
else
    echo -e "${RED}❌ Local AWS CLI not configured${NC}"
    echo "   Run: aws configure"
    exit 1
fi

echo -e "\n${YELLOW}2. Testing IAM permissions...${NC}"
if aws iam get-user >/dev/null 2>&1; then
    echo -e "${GREEN}✅ IAM permissions working${NC}"
else
    echo -e "${RED}❌ No IAM permissions (might be normal for root users)${NC}"
fi

echo -e "\n${YELLOW}3. GitHub Secrets Needed:${NC}"
echo "   AWS_ACCESS_KEY_ID: [Your AWS Access Key]"
echo "   AWS_SECRET_ACCESS_KEY: [Your AWS Secret Key]"
echo "   AWS_ACCOUNT_ID: $ACCOUNT_ID (optional)"

echo -e "\n${YELLOW}4. GitHub Repository Settings:${NC}"
echo "   Go to: Settings → Secrets and variables → Actions"
echo "   Add the secrets listed above"

echo -e "\n${YELLOW}5. Workflow Region Check:${NC}"
WORKFLOW_REGION=$(grep "AWS_REGION:" .github/workflows/deploy.yml | cut -d' ' -f4)
CURRENT_REGION=$(aws configure get region || echo "not-set")
echo "   Workflow expects: $WORKFLOW_REGION"
echo "   Your CLI region: $CURRENT_REGION"

if [ "$WORKFLOW_REGION" != "$CURRENT_REGION" ] && [ "$CURRENT_REGION" != "not-set" ]; then
    echo -e "${YELLOW}   ⚠️  Region mismatch detected${NC}"
    echo "   Consider updating the workflow region or using the CLI region"
fi

echo -e "\n${GREEN}🎯 Next Steps:${NC}"
echo "1. Add AWS secrets to GitHub repository"
echo "2. Make sure secret names match exactly"
echo "3. Test by pushing a commit or creating a PR"
echo "4. Check GitHub Actions logs for detailed errors"
