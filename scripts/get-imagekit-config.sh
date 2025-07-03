#!/bin/bash

# ImageKit Credentials Extractor
# This script extracts the required parameters for ImageKit configuration

echo "🔧 Extracting ImageKit Configuration Parameters"
echo "=============================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

STACK_NAME="ShloInfraStack"
REGION=$(aws configure get region || echo "us-east-2")

echo -e "${YELLOW}Fetching stack outputs from AWS...${NC}"

# Function to get stack output
get_output() {
    local output_key=$1
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query "Stacks[0].Outputs[?OutputKey=='$output_key'].OutputValue" \
        --output text 2>/dev/null
}

# Get all required outputs
BUCKET_NAME=$(get_output "ImageStorageBucketName")
ACCESS_KEY_ID=$(get_output "ImageKitAccessKeyId")
SECRET_ACCESS_KEY=$(get_output "ImageKitSecretAccessKey")
BUCKET_REGION=$(get_output "BucketRegion")
CLOUDFRONT_DOMAIN=$(get_output "CloudFrontDomainName")

# Check if stack exists and has outputs
if [ -z "$BUCKET_NAME" ]; then
    echo -e "${RED}❌ Could not find stack outputs. Make sure the stack is deployed.${NC}"
    echo -e "${YELLOW}💡 Run 'npm run deploy' to deploy the stack first.${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ ImageKit Configuration Parameters:${NC}"
echo "================================================"
echo ""
echo "📋 Use these values in ImageKit dashboard:"
echo ""
echo -e "${YELLOW}Bucket Name:${NC}        $BUCKET_NAME"
echo -e "${YELLOW}Bucket Folder:${NC}      images/"
echo -e "${YELLOW}Access Key:${NC}         $ACCESS_KEY_ID"
echo -e "${YELLOW}Secret Key:${NC}         $SECRET_ACCESS_KEY"
echo -e "${YELLOW}Bucket Region:${NC}      $BUCKET_REGION"
echo ""
echo -e "${YELLOW}Optional CloudFront CDN:${NC} $CLOUDFRONT_DOMAIN"
echo ""
echo -e "${RED}⚠️  SECURITY WARNING:${NC}"
echo "- Keep the Secret Key secure and private"
echo "- Never commit these credentials to version control"
echo "- Consider storing them in a password manager"
echo ""
echo -e "${GREEN}🚀 Ready to configure ImageKit!${NC}"
echo ""
echo "Next steps:"
echo "1. Go to ImageKit dashboard → Settings → Storage"
echo "2. Add External Storage → Amazon S3"
echo "3. Use the parameters above"
echo "4. Test the connection"
