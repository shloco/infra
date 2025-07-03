import * as cdk from 'aws-cdk-lib'
import * as s3 from 'aws-cdk-lib/aws-s3'
import * as iam from 'aws-cdk-lib/aws-iam'
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront'
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins'
import { Construct } from 'constructs'

export class ShloInfraStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props)

    // S3 bucket for ImageKit image storage
    const imageStorageBucket = new s3.Bucket(this, 'ImageStorageBucket', {
      bucketName: `shlo-imagekit-storage-${cdk.Stack.of(this).account}-${
        cdk.Stack.of(this).region
      }`,
      versioned: true,
      removalPolicy: cdk.RemovalPolicy.RETAIN, // Keep images in production
      autoDeleteObjects: false, // Don't auto-delete images
      blockPublicAccess: new s3.BlockPublicAccess({
        blockPublicAcls: true,
        blockPublicPolicy: true,
        ignorePublicAcls: true,
        restrictPublicBuckets: false, // Allow ImageKit to access via bucket policy
      }),
      encryption: s3.BucketEncryption.S3_MANAGED,
      cors: [
        {
          allowedMethods: [
            s3.HttpMethods.GET,
            s3.HttpMethods.PUT,
            s3.HttpMethods.POST,
            s3.HttpMethods.DELETE,
          ],
          allowedOrigins: ['*'], // Configure with your domain for production
          allowedHeaders: ['*'],
          maxAge: 3000,
        },
      ],
      lifecycleRules: [
        {
          id: 'OptimizeStorageCosts',
          enabled: true,
          transitions: [
            {
              storageClass: s3.StorageClass.INFREQUENT_ACCESS,
              transitionAfter: cdk.Duration.days(30),
            },
            {
              storageClass: s3.StorageClass.GLACIER,
              transitionAfter: cdk.Duration.days(90),
            },
            {
              storageClass: s3.StorageClass.DEEP_ARCHIVE,
              transitionAfter: cdk.Duration.days(365),
            },
          ],
        },
      ],
    })

    // IAM user for ImageKit to access S3 (ImageKit requires access keys)
    const imageKitUser = new iam.User(this, 'ImageKitUser', {
      userName: `shlo-imagekit-user-${cdk.Stack.of(this).region}`,
      path: '/imagekit/',
    })

    // IAM policy for ImageKit S3 access
    const imageKitPolicy = new iam.Policy(this, 'ImageKitPolicy', {
      policyName: `shlo-imagekit-policy-${cdk.Stack.of(this).region}`,
      statements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            's3:GetObject',
            's3:PutObject',
            's3:DeleteObject',
            's3:ListBucket',
            's3:GetBucketLocation',
          ],
          resources: [
            imageStorageBucket.bucketArn,
            `${imageStorageBucket.bucketArn}/*`,
          ],
        }),
      ],
    })

    // Attach policy to user
    imageKitUser.attachInlinePolicy(imageKitPolicy)

    // Create access keys for ImageKit user
    const imageKitAccessKey = new iam.AccessKey(this, 'ImageKitAccessKey', {
      user: imageKitUser,
    })

    // CloudFront distribution for CDN (optional but recommended)
    const distribution = new cloudfront.Distribution(this, 'ImageCDN', {
      defaultBehavior: {
        origin:
          origins.S3BucketOrigin.withOriginAccessControl(imageStorageBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        compress: true,
      },
      priceClass: cloudfront.PriceClass.PRICE_CLASS_100, // Use only North America and Europe
      comment: 'Shlo ImageKit CDN Distribution',
      enabled: true,
    })

    // Outputs for ImageKit configuration
    new cdk.CfnOutput(this, 'ImageStorageBucketName', {
      value: imageStorageBucket.bucketName,
      description: 'S3 bucket name for ImageKit storage',
      exportName: 'ShloImageStorageBucketName',
    })

    new cdk.CfnOutput(this, 'ImageStorageBucketArn', {
      value: imageStorageBucket.bucketArn,
      description: 'ARN of the S3 bucket for ImageKit storage',
      exportName: 'ShloImageStorageBucketArn',
    })

    new cdk.CfnOutput(this, 'ImageKitAccessKeyId', {
      value: imageKitAccessKey.accessKeyId,
      description: 'Access Key ID for ImageKit user',
      exportName: 'ShloImageKitAccessKeyId',
    })

    new cdk.CfnOutput(this, 'ImageKitSecretAccessKey', {
      value: imageKitAccessKey.secretAccessKey.unsafeUnwrap(),
      description: 'Secret Access Key for ImageKit user (handle securely!)',
      exportName: 'ShloImageKitSecretAccessKey',
    })

    new cdk.CfnOutput(this, 'ImageKitUserArn', {
      value: imageKitUser.userArn,
      description: 'ARN of the IAM user for ImageKit',
      exportName: 'ShloImageKitUserArn',
    })

    new cdk.CfnOutput(this, 'BucketRegion', {
      value: cdk.Stack.of(this).region,
      description: 'AWS region where the bucket is located',
      exportName: 'ShloBucketRegion',
    })

    new cdk.CfnOutput(this, 'CloudFrontDistributionId', {
      value: distribution.distributionId,
      description: 'CloudFront distribution ID for image CDN',
      exportName: 'ShloCloudFrontDistributionId',
    })

    new cdk.CfnOutput(this, 'CloudFrontDomainName', {
      value: distribution.distributionDomainName,
      description: 'CloudFront distribution domain name',
      exportName: 'ShloCloudFrontDomainName',
    })
  }
}
