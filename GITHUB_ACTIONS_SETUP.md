# GitHub Actions Setup Guide

This guide will help you set up automated deployment of your CDK infrastructure using GitHub Actions.

## 🔧 Prerequisites

1. **GitHub Repository**: Your code should be in a GitHub repository
2. **AWS Account**: Access to an AWS account where you want to deploy
3. **AWS IAM User**: A dedicated IAM user for GitHub Actions with appropriate permissions

## 🔑 AWS IAM Setup

### Step 1: Create an IAM User for GitHub Actions

1. Go to the AWS IAM Console
2. Create a new user called `github-actions-cdk`
3. Attach the following managed policies:
   - `PowerUserAccess` (or create a custom policy with specific permissions)
   - `IAMFullAccess` (needed for CDK to create IAM roles)

### Step 2: Alternative - Use IAM Roles with OIDC (Recommended for Security)

For better security, you can use OpenID Connect (OIDC) instead of long-lived access keys:

```bash
# Create the OIDC provider (run once per AWS account)
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

Then create an IAM role that can be assumed by GitHub Actions.

## 🔐 GitHub Secrets Setup

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions** and add:

### Required Secrets:

- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key
- `AWS_ACCOUNT_ID`: Your 12-digit AWS account ID (e.g., 123456789012)

### Optional Secrets:

- `AWS_REGION`: AWS region (defaults to us-east-2 in the workflow)

## 🏗️ GitHub Environments Setup

1. Go to **Settings** → **Environments** in your GitHub repository
2. Create two environments:

   - `staging` - For pull request deployments
   - `production` - For main branch deployments

3. For each environment, you can set:
   - **Required reviewers**: People who must approve deployments
   - **Wait timer**: Delay before deployment starts
   - **Deployment branches**: Which branches can deploy to this environment

## 📋 Workflow Files Created

I've created three GitHub Actions workflows:

### 1. `deploy.yml` - Main Deployment Pipeline

- **Triggers**: Push to main/master, Pull Requests
- **Jobs**:
  - `test`: Runs tests, linting, and CDK synth
  - `deploy-staging`: Deploys to staging on PRs
  - `deploy-production`: Deploys to production on main branch

### 2. `security.yml` - Security and Quality Checks

- **Triggers**: Push, PRs, weekly schedule
- **Jobs**:
  - Security scanning with npm audit
  - Dependency checks
  - CDK security best practices

### 3. `destroy.yml` - Resource Cleanup

- **Triggers**: Manual workflow dispatch only
- **Purpose**: Safely destroy CDK resources when needed
- **Safety**: Requires typing "destroy" to confirm

## 🚀 Deployment Flow

### For Pull Requests:

1. Code is pushed to a feature branch
2. PR is created → triggers staging deployment
3. Tests run automatically
4. If tests pass → deploys to staging environment
5. Review and merge the PR

### For Production:

1. PR is merged to main/master
2. Triggers production deployment
3. Tests run again
4. If tests pass → deploys to production environment

## 🔧 Customization Options

### Modify Deployment Regions

Edit the `AWS_REGION` environment variable in `.github/workflows/deploy.yml`:

```yaml
env:
  AWS_REGION: us-west-2 # Change to your preferred region
```

### Add Environment-Specific Stacks

You can modify your CDK app to deploy different stacks for different environments:

```typescript
// In bin/app.ts
const envConfig = {
  staging: { account: '111111111111', region: 'us-east-2' },
  production: { account: '222222222222', region: 'us-east-1' },
}

const environment = process.env.ENVIRONMENT || 'production'
const env = envConfig[environment]
```

### Add Approval Gates

In your GitHub environment settings, you can require manual approval before production deployments.

## 🔍 Monitoring and Debugging

### View Deployment Logs

1. Go to **Actions** tab in your GitHub repository
2. Click on any workflow run to see detailed logs
3. Each job shows step-by-step execution

### Common Issues and Solutions

**Issue**: CDK Bootstrap fails
**Solution**: Make sure your AWS account has never used CDK before, or the bootstrap stack exists

**Issue**: Permission denied errors
**Solution**: Check that your IAM user/role has sufficient permissions

**Issue**: Region mismatch
**Solution**: Ensure `AWS_REGION` in workflows matches your CDK app configuration

## 🎯 Next Steps

1. **Push your code** to GitHub to trigger the first workflow
2. **Create a pull request** to test staging deployment
3. **Monitor the Actions tab** to see deployment progress
4. **Check AWS Console** to verify resources are created
5. **Merge to main** to deploy to production

## 🛡️ Security Best Practices

- ✅ Use environment-specific AWS accounts when possible
- ✅ Enable CloudTrail for audit logging
- ✅ Set up AWS Config for compliance monitoring
- ✅ Use least-privilege IAM policies
- ✅ Regularly rotate access keys
- ✅ Monitor AWS costs and usage

## 📞 Support

If you encounter issues:

1. Check the GitHub Actions logs
2. Review AWS CloudFormation events in the AWS Console
3. Ensure all secrets are properly configured
4. Verify IAM permissions are sufficient

Happy deploying! 🚀
