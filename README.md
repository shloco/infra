# Shlo Infrastructure

This repository contains the Infrastructure as Code (IaC) for the Shlo project using AWS CDK.

## 🏗️ What This Creates

- **S3 Bucket**: Secure storage for ImageKit with versioning, encryption, and CORS
- **IAM User**: Service account for ImageKit with minimal required permissions
- **CloudFront CDN**: Global content delivery for fast image loading
- **GitHub Actions**: Automated deployment using secure OIDC authentication

## 🔐 Authentication

This project uses **two different authentication methods**:

- **GitHub Actions**: OIDC (no access keys needed in GitHub!) 🎉
- **ImageKit**: IAM User with access keys (created automatically)

See [Authentication Guide](./docs/AUTHENTICATION_GUIDE.md) for details.

## Prerequisites

- Node.js (v18 or later)
- AWS CLI configured with appropriate credentials
- AWS CDK CLI (`npm install -g aws-cdk`)

## 🚀 Quick Start

1. **Install dependencies:**

   ```bash
   npm install
   ```

2. **Bootstrap your AWS environment** (only needed once per AWS account/region):

   ```bash
   npm run cdk bootstrap
   ```

3. **Build the project:**

   ```bash
   npm run build
   ```

4. **Preview what will be deployed:**

   ```bash
   npm run synth
   ```

5. **Deploy the stack:**
   ```bash
   npm run deploy
   ```

## Project Structure

- `bin/app.ts` - Entry point for the CDK application
- `lib/shlo-infra-stack.ts` - Main infrastructure stack
- `cdk.json` - CDK configuration file
- `package.json` - Node.js dependencies and scripts

## Available Scripts

- `npm run build` - Compile TypeScript to JavaScript
- `npm run watch` - Watch for changes and compile
- `npm run test` - Run tests
- `npm run synth` - Synthesize CloudFormation template
- `npm run deploy` - Deploy the stack to AWS
- `npm run destroy` - Destroy the stack (be careful!)
- `npm run diff` - Show differences between deployed stack and current code

## 📦 Infrastructure Components

The current stack includes:

- **S3 Bucket**: ImageKit storage with versioning, encryption, lifecycle rules, and CORS
- **IAM User**: Service account for ImageKit with minimal S3 permissions
- **CloudFront CDN**: Global content delivery for fast image loading
- **Stack Outputs**: Easy access to bucket name, access keys, and CDN URL

## 🛠️ Configuration

### GitHub Actions Setup
1. **Set up OIDC**: Follow [OIDC Setup Guide](./docs/OIDC_SETUP.md)
2. **Add secrets**: Only `AWS_ROLE_ARN` and `AWS_ACCOUNT_ID` needed
3. **Deploy**: GitHub Actions will automatically deploy on push to main

### ImageKit Setup
1. **Deploy infrastructure**: `npm run deploy`
2. **Get credentials**: `./scripts/get-imagekit-config.sh`
3. **Configure ImageKit**: Follow [ImageKit Setup Guide](./docs/IMAGEKIT_SETUP.md)

## 🔒 Security Features

This infrastructure follows AWS security best practices:

- ✅ **S3 Encryption**: Server-side encryption enabled
- ✅ **Access Control**: Block public access enabled
- ✅ **IAM Principles**: Least privilege access for ImageKit user
- ✅ **CloudFront Security**: Origin Access Control (OAC) configured
- ✅ **OIDC Authentication**: No long-lived credentials in GitHub
- ✅ **Versioning**: S3 object versioning enabled

## 💰 Cost Optimization

- **S3 Lifecycle Rules**: Automatically move old versions to cheaper storage
- **CloudFront Caching**: Reduces origin requests and costs
- **Pay-per-use**: Only pay for storage and transfer you actually use
- **Regional Optimization**: Deployed in us-east-2 for cost efficiency

## 🔧 Development

### Adding New Resources
1. Edit `lib/shlo-infra-stack.ts`
2. Update tests in `test/shlo-infra.test.ts`
3. Run `npm test` to verify
4. Deploy with `npm run deploy`

### Local Testing
```bash
npm run build    # Compile TypeScript
npm test         # Run tests
npm run synth    # Generate CloudFormation template
```

## 🧹 Cleanup

To destroy resources when not needed:

```bash
npm run destroy
```

Or use the GitHub Actions destroy workflow for safer cleanup.

**⚠️ Warning**: This will delete all resources. Ensure you have backups of any important data.

## 📚 Documentation

- [Authentication Guide](./docs/AUTHENTICATION_GUIDE.md) - Overview of OIDC vs Access Key usage
- [OIDC Setup Guide](./docs/OIDC_SETUP.md) - GitHub Actions OIDC configuration  
- [ImageKit Setup Guide](./docs/IMAGEKIT_SETUP.md) - Complete ImageKit integration
- [GitHub Actions Fix Guide](./docs/GITHUB_ACTIONS_FIX.md) - Troubleshooting CI/CD issues

## 🚨 Troubleshooting

### Common Issues

1. **GitHub Actions failing**: Check OIDC setup and role permissions
2. **ImageKit access denied**: Verify IAM user has S3 permissions
3. **CDK bootstrap issues**: Ensure AWS CLI is configured correctly

### Getting Help

- Check the troubleshooting sections in each documentation file
- Review CloudTrail logs for permission issues
- Verify all required GitHub secrets are set correctly

This project includes automated deployment using GitHub Actions. See the setup guides:

- **[GitHub Actions Setup Guide](GITHUB_ACTIONS_SETUP.md)** - Complete setup instructions
- **[OIDC Setup Guide](docs/OIDC_SETUP.md)** - Secure authentication with OpenID Connect (recommended)

### Workflows Included:
- **Deploy Pipeline** (`.github/workflows/deploy.yml`) - Automated testing and deployment
- **Security Checks** (`.github/workflows/security.yml`) - Security scanning and dependency checks  
- **Resource Cleanup** (`.github/workflows/destroy.yml`) - Safe resource destruction

### Deployment Flow:
- **Pull Requests** → Deploy to staging environment
- **Main Branch** → Deploy to production environment
- **Manual Trigger** → Destroy resources when needed
