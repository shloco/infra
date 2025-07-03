# GitHub Actions OIDC Setup (Recommended)

This guide shows how to set up GitHub Actions with OpenID Connect (OIDC) for better security instead of long-lived access keys.

## 🔐 Why OIDC?

- ✅ **No long-lived credentials** stored in GitHub
- ✅ **Short-lived tokens** that expire automatically
- ✅ **Fine-grained permissions** based on repository and branch
- ✅ **Better audit trail** in AWS CloudTrail

## 🏗️ AWS Setup

### Step 1: Create OIDC Identity Provider

```bash
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    --thumbprint-list 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```

### Step 2: Create IAM Role

Create a file called `github-actions-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

Replace:

- `YOUR_ACCOUNT_ID` with your AWS account ID
- `YOUR_GITHUB_USERNAME` with your GitHub username
- `YOUR_REPO_NAME` with your repository name

### Step 3: Create the Role

```bash
aws iam create-role \
    --role-name GitHubActionsCDKRole \
    --assume-role-policy-document file://github-actions-trust-policy.json
```

### Step 4: Attach Permissions

```bash
# Option 1: Use the custom policy we created
aws iam attach-role-policy \
    --role-name GitHubActionsCDKRole \
    --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/GitHubActionsCDKPolicy

# Option 2: Use AWS managed policies (less secure but simpler)
aws iam attach-role-policy \
    --role-name GitHubActionsCDKRole \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

aws iam attach-role-policy \
    --role-name GitHubActionsCDKRole \
    --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
```

## 🔧 GitHub Secrets Setup

Instead of AWS credentials, you only need:

- `AWS_ROLE_ARN`: The ARN of the role you created (e.g., `arn:aws:iam::123456789012:role/GitHubActionsCDKRole`)
- `AWS_ACCOUNT_ID`: Your AWS account ID

## 📝 Updated Workflow

Here's the updated workflow configuration for OIDC:

```yaml
name: Deploy CDK Infrastructure (OIDC)

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

permissions:
  id-token: write # This is required for requesting the JWT
  contents: read # This is required for actions/checkout

env:
  AWS_REGION: us-east-2

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build and test
        run: |
          npm run build
          npm test

      - name: CDK Deploy
        run: npm run deploy -- --require-approval never
```

## 🔍 Troubleshooting

### Common Issues:

1. **"No credentials available"**

   - Ensure `permissions.id-token: write` is set in your workflow
   - Verify the role ARN is correct

2. **"Access denied"**

   - Check the trust policy allows your repository
   - Verify the role has necessary permissions

3. **"Invalid identity token"**
   - Ensure OIDC provider is created correctly
   - Check thumbprints are up to date

### Debug Steps:

1. **Test the role assumption**:

   ```bash
   aws sts get-caller-identity
   ```

2. **Check CloudTrail logs** for detailed error messages

3. **Validate trust policy** matches your repository path exactly

## 🎯 Benefits of This Setup

- **Security**: No long-lived credentials in GitHub
- **Compliance**: Better audit trail and access control
- **Maintenance**: No need to rotate access keys
- **Granular**: Can restrict access to specific branches/tags

## 🔄 Migration from Access Keys

If you're migrating from access keys:

1. Set up OIDC as described above
2. Update your workflow to use the new authentication method
3. Test thoroughly in a staging environment
4. Remove the old access key secrets from GitHub
5. Delete the old IAM user from AWS

This approach provides much better security for your CI/CD pipeline!
