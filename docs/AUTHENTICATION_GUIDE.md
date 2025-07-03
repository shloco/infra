# Authentication Guide

## 🔐 Authentication Methods Overview

This project uses **two different authentication approaches** for different purposes:

### 1. **GitHub Actions ↔ AWS: OIDC (Recommended)**
- **Purpose**: Deploy infrastructure via GitHub Actions
- **Method**: OpenID Connect (OIDC) with temporary credentials
- **Benefits**: No long-lived credentials, better security
- **Setup**: See [OIDC_SETUP.md](./OIDC_SETUP.md)

### 2. **ImageKit ↔ AWS: Access Keys (Required)**
- **Purpose**: ImageKit service needs direct access to S3
- **Method**: IAM User with access keys
- **Why**: ImageKit doesn't support OIDC, requires traditional access keys
- **Setup**: Automatically created by CDK stack

## 🔄 Authentication Flow

```
┌─────────────────┐    OIDC     ┌─────────────┐
│  GitHub Actions │ ──────────► │ AWS Account │
└─────────────────┘             └─────────────┘
                                       │
                                       │ Creates
                                       ▼
                                ┌─────────────────┐
                                │ IAM User +      │
                                │ Access Keys     │
                                └─────────────────┘
                                       │
                                       │ Used by
                                       ▼
                                ┌─────────────────┐
                                │    ImageKit     │
                                └─────────────────┘
```

## 🚀 Getting Started

### Step 1: Set up OIDC for GitHub Actions
Follow the [OIDC Setup Guide](./OIDC_SETUP.md) to configure secure GitHub Actions deployment.

### Step 2: Deploy Infrastructure
```bash
# Deploy CDK stack (creates S3 bucket + IAM user for ImageKit)
npm run deploy
```

### Step 3: Configure ImageKit
Follow the [ImageKit Setup Guide](./IMAGEKIT_SETUP.md) to integrate with your S3 bucket.

## 🔧 Required GitHub Secrets

For OIDC authentication, you only need:
- `AWS_ROLE_ARN` - The ARN of your GitHub Actions role
- `AWS_ACCOUNT_ID` - Your AWS account ID

**No AWS access keys needed in GitHub!** 🎉

## 📋 Quick Reference

| Component | Authentication | Credentials Location |
|-----------|---------------|---------------------|
| GitHub Actions | OIDC | GitHub Secrets (Role ARN) |
| ImageKit | Access Keys | CDK Stack Outputs |
| Local Development | AWS CLI Profile | `~/.aws/credentials` |

## 🔍 Troubleshooting

### GitHub Actions Issues
- Ensure `permissions.id-token: write` is set in workflow
- Verify `AWS_ROLE_ARN` secret is correct
- Check OIDC trust policy allows your repository

### ImageKit Issues
- Get access keys from CDK outputs: `./scripts/get-imagekit-config.sh`
- Ensure IAM user has S3 permissions
- Check S3 bucket exists and has correct permissions

## 🛡️ Security Best Practices

1. **Use OIDC for CI/CD** - No long-lived credentials in GitHub
2. **Rotate ImageKit keys** regularly (consider using AWS Secrets Manager)
3. **Monitor access** via CloudTrail
4. **Use least privilege** principles for all IAM policies
5. **Enable MFA** on your AWS root account
