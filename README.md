# Shlo Infrastructure

This repository contains the Infrastructure as Code (IaC) for the Shlo project using AWS CDK.

## Prerequisites

- Node.js (v18 or later)
- AWS CLI configured with appropriate credentials
- AWS CDK CLI (`npm install -g aws-cdk`)

## Getting Started

1. Install dependencies:

   ```bash
   npm install
   ```

2. Bootstrap your AWS environment (only needed once per AWS account/region):

   ```bash
   npm run cdk bootstrap
   ```

3. Build the project:

   ```bash
   npm run build
   ```

4. View the CloudFormation template that will be deployed:

   ```bash
   npm run synth
   ```

5. Deploy the stack:
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

## Example Resources

The current stack includes:

- **S3 Bucket**: For storing assets with versioning and encryption
- **Lambda Function**: Example serverless function
- **IAM Permissions**: Proper permissions between resources

## Environment Variables

The stack uses the following environment variables:

- `CDK_DEFAULT_ACCOUNT` - AWS account ID (automatically detected)
- `CDK_DEFAULT_REGION` - AWS region (defaults to us-east-1)

## Security Best Practices

This template includes several security best practices:

- S3 bucket with block public access enabled
- S3 bucket encryption
- Minimal IAM permissions
- Secure defaults for all resources

## Customization

To add new resources:

1. Import the required AWS CDK modules in `lib/shlo-infra-stack.ts`
2. Add your resources in the constructor
3. Set up any necessary permissions
4. Add outputs if needed

## Cost Considerations

- The S3 bucket uses standard storage class
- Lambda functions are billed per request and execution time
- Consider using Reserved Instances for predictable workloads

## Cleanup

To avoid charges, destroy resources when not needed:

```bash
npm run destroy
```

**Warning**: This will delete all resources. Make sure you have backups of any important data.
