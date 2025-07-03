#!/bin/bash

# Quick test script to check AWS CLI and jq
echo "🔍 Testing AWS CLI and dependencies..."

# Test AWS CLI
echo -n "AWS CLI: "
if command -v aws &> /dev/null; then
    echo "✅ Installed"
    echo -n "AWS Auth: "
    if aws sts get-caller-identity >/dev/null 2>&1; then
        echo "✅ Working"
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        echo "Account ID: $ACCOUNT_ID"
    else
        echo "❌ Not configured"
        exit 1
    fi
else
    echo "❌ Not installed"
    exit 1
fi

# Test jq
echo -n "jq: "
if command -v jq &> /dev/null; then
    echo "✅ Installed"
else
    echo "❌ Not installed"
    echo "Install with: brew install jq"
    exit 1
fi

# Test IAM permissions
echo -n "IAM permissions: "
if aws iam get-user >/dev/null 2>&1; then
    echo "✅ Can access IAM"
else
    echo "❌ Cannot access IAM (this might be normal if using root account)"
fi

# Test policy creation (dry run)
echo -n "Policy file: "
if [ -f "docs/github-actions-iam-policy.json" ]; then
    echo "✅ Found"
    # Validate JSON
    if jq empty docs/github-actions-iam-policy.json >/dev/null 2>&1; then
        echo "JSON is valid ✅"
    else
        echo "JSON is invalid ❌"
        exit 1
    fi
else
    echo "❌ Missing docs/github-actions-iam-policy.json"
    exit 1
fi

echo ""
echo "🎉 All checks passed! You can run the setup script now."
