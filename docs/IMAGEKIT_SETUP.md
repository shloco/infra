# ImageKit S3 Integration Guide

This guide explains how to configure ImageKit to use your AWS S3 bucket for image storage.

## 🏗️ Infrastructure Created

Your CDK stack creates the following resources for ImageKit:

### 1. **S3 Bucket** (`ImageStorageBucket`)

- **Purpose**: Store original images and processed versions
- **Features**:
  - ✅ Versioning enabled
  - ✅ Server-side encryption (AES256)
  - ✅ CORS configuration for web uploads
  - ✅ Lifecycle rules for cost optimization
  - ✅ Production-ready retention policy

### 2. **IAM User** (`ImageKitUser`)

- **Purpose**: Provide access keys for ImageKit to access your S3 bucket
- **Permissions**:
  - `s3:GetObject` - Read images
  - `s3:PutObject` - Upload images
  - `s3:DeleteObject` - Delete images
  - `s3:ListBucket` - List bucket contents
  - `s3:GetBucketLocation` - Get bucket region info

### 3. **CloudFront Distribution** (`ImageCDN`)

- **Purpose**: CDN for fast global image delivery
- **Features**:
  - ✅ Origin Access Control (OAC) for security
  - ✅ HTTPS redirect
  - ✅ Gzip compression
  - ✅ Optimized caching policy
  - ✅ Global edge locations

## 📋 ImageKit Configuration Steps

### Step 1: Deploy Your Infrastructure

```bash
# Build and deploy your CDK stack
npm run build
npm run deploy
```

After deployment, get the required parameters:

**Option 1: Use the helper script**

```bash
./scripts/get-imagekit-config.sh
```

**Option 2: Manual extraction from AWS Console**
Go to CloudFormation → ShloInfraStack → Outputs tab and note:

- `ImageStorageBucketName` - Your S3 bucket name
- `ImageKitAccessKeyId` - Access key for ImageKit
- `ImageKitSecretAccessKey` - Secret key for ImageKit ⚠️ **Keep secure!**
- `BucketRegion` - AWS region
- `CloudFrontDomainName` - CDN endpoint (optional)

### Step 2: Configure ImageKit External Storage

1. **Log into ImageKit Dashboard**

   - Go to [ImageKit.io Dashboard](https://imagekit.io/dashboard)
   - Navigate to **Settings** → **Storage**

2. **Add External Storage**

   - Click **Add External Storage**
   - Select **Amazon S3**

3. **S3 Configuration**

   ```
   Storage Name: Shlo Images
   S3 Bucket Name: [Use ImageStorageBucketName from CDK output]
   S3 Bucket Region: [Use BucketRegion from CDK output]
   Bucket Folder: images/ (optional - organizes your files)
   ```

4. **Authentication Method**

   - Select **Access Key** authentication
   - Access Key: `[Use ImageKitAccessKeyId from CDK output]`
   - Secret Key: `[Use ImageKitSecretAccessKey from CDK output]`

5. **Optional Settings**
   ```
   S3 Object ACL: private (recommended)
   Enable signed URLs: Yes (for private images)
   ```

### Step 3: Configure ImageKit URL Endpoint (Optional)

If you want to use CloudFront for delivery:

1. **Add URL Endpoint**

   - Go to **Settings** → **URL Endpoints**
   - Click **Add URL Endpoint**

2. **CloudFront Configuration**
   ```
   URL Endpoint Name: Shlo CDN
   Origin: [Use CloudFrontDomainName from CDK output]
   Origin Type: Web Server
   ```

## 🔧 Advanced Configuration

### Custom Domain for CloudFront

To use your own domain (e.g., `images.shlo.com`):

1. **Update CDK Stack** (add to `lib/shlo-infra-stack.ts`):

   ```typescript
   // Add certificate and domain configuration
   const certificate = acm.Certificate.fromCertificateArn(
     this,
     'Certificate',
     'arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID'
   )

   const distribution = new cloudfront.Distribution(this, 'ImageCDN', {
     // ...existing config...
     domainNames: ['images.shlo.com'],
     certificate: certificate,
   })
   ```

2. **Add DNS Record**
   - Point `images.shlo.com` CNAME to CloudFront domain

### Image Upload Policies

For direct uploads from your application:

```typescript
// Add to your CDK stack
const uploadPolicy = new iam.Policy(this, 'DirectUploadPolicy', {
  statements: [
    new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['s3:PutObject'],
      resources: [`${imageStorageBucket.bucketArn}/uploads/*`],
      conditions: {
        StringEquals: {
          's3:x-amz-content-sha256': 'UNSIGNED-PAYLOAD',
        },
      },
    }),
  ],
})
```

## 🛡️ Security Best Practices

### 1. **Secret Key Handling** ⚠️ **IMPORTANT**

- The `ImageKitSecretAccessKey` output contains sensitive credentials
- **Never commit these keys to version control**
- Store them securely in your password manager
- Rotate keys regularly (every 90 days recommended)
- Consider using AWS Secrets Manager for production

### 2. **Bucket Access**

- ✅ Public read access is blocked
- ✅ Only ImageKit user can access via access keys
- ✅ CloudFront uses Origin Access Control

### 3. **CORS Configuration**

```json
{
  "allowedMethods": ["GET", "PUT", "POST", "DELETE"],
  "allowedOrigins": ["*"], // Update with your domain
  "allowedHeaders": ["*"],
  "maxAge": 3000
}
```

### 4. **IAM User Policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket-name",
        "arn:aws:s3:::your-bucket-name/*"
      ]
    }
  ]
}
```

## 💰 Cost Optimization

### Storage Classes

The bucket includes automatic lifecycle transitions:

- **30 days** → Standard-IA (cheaper for infrequent access)
- **90 days** → Glacier (archival storage)
- **365 days** → Deep Archive (long-term archival)

### CloudFront Pricing

- Using **Price Class 100** (North America + Europe only)
- For global coverage, change to `PRICE_CLASS_ALL`

## 📊 Monitoring

### CloudWatch Metrics

Monitor these key metrics:

- S3 bucket size and request count
- CloudFront cache hit ratio
- ImageKit transformation usage

### Cost Alerts

Set up billing alerts for:

- S3 storage costs
- CloudFront data transfer
- ImageKit transformation costs

## 🚨 Troubleshooting

### Common Issues

**Issue**: ImageKit can't access S3 bucket
**Solution**:

- Verify IAM role ARN is correct
- Check trust policy allows ImageKit service
- Ensure region matches

**Issue**: Images not loading via CloudFront
**Solution**:

- Verify Origin Access Control is configured
- Check S3 bucket policy allows CloudFront
- Wait for distribution deployment (can take 15+ minutes)

**Issue**: CORS errors during upload
**Solution**:

- Update CORS configuration with your domain
- Ensure `allowedMethods` includes required verbs

### Debug Commands

```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket YOUR_BUCKET_NAME

# Test role assumption
aws sts assume-role --role-arn YOUR_ROLE_ARN --role-session-name test

# Check CloudFront distribution status
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID
```

## 🔄 Updates and Maintenance

### Updating the Stack

```bash
# Deploy changes
npm run diff  # Review changes first
npm run deploy

# Update ImageKit configuration if needed
```

### Backup Strategy

- S3 versioning provides automatic backup
- Consider cross-region replication for critical images
- Regular exports to another storage service

## 📞 Support

For issues with:

- **AWS Resources**: Check CloudFormation events in AWS Console
- **ImageKit Integration**: Contact ImageKit support with your setup details
- **CDK Deployment**: Check GitHub Actions logs or local terminal output

Your ImageKit integration is now ready for production use! 🚀
