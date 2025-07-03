import { Template } from 'aws-cdk-lib/assertions'
import * as cdk from 'aws-cdk-lib'
import { ShloInfraStack } from '../lib/shlo-infra-stack'

test('ImageKit S3 Bucket Created', () => {
  const app = new cdk.App()
  const stack = new ShloInfraStack(app, 'TestStack')
  const template = Template.fromStack(stack)

  template.hasResourceProperties('AWS::S3::Bucket', {
    VersioningConfiguration: {
      Status: 'Enabled',
    },
    BucketEncryption: {
      ServerSideEncryptionConfiguration: [
        {
          ServerSideEncryptionByDefault: {
            SSEAlgorithm: 'AES256',
          },
        },
      ],
    },
  })
})

test('ImageKit IAM User Created', () => {
  const app = new cdk.App()
  const stack = new ShloInfraStack(app, 'TestStack')
  const template = Template.fromStack(stack)

  template.hasResourceProperties('AWS::IAM::User', {
    Path: '/imagekit/',
  })
})

test('ImageKit Access Keys Created', () => {
  const app = new cdk.App()
  const stack = new ShloInfraStack(app, 'TestStack')
  const template = Template.fromStack(stack)

  template.hasResourceProperties('AWS::IAM::AccessKey', {})
})

test('CloudFront Distribution Created', () => {
  const app = new cdk.App()
  const stack = new ShloInfraStack(app, 'TestStack')
  const template = Template.fromStack(stack)

  template.hasResourceProperties('AWS::CloudFront::Distribution', {
    DistributionConfig: {
      Enabled: true,
    },
  })
})

test('Stack has required outputs', () => {
  const app = new cdk.App()
  const stack = new ShloInfraStack(app, 'TestStack')
  const template = Template.fromStack(stack)

  template.hasOutput('ImageStorageBucketName', {})
  template.hasOutput('ImageStorageBucketArn', {})
  template.hasOutput('ImageKitAccessKeyId', {})
  template.hasOutput('ImageKitSecretAccessKey', {})
  template.hasOutput('ImageKitUserArn', {})
  template.hasOutput('BucketRegion', {})
  template.hasOutput('CloudFrontDistributionId', {})
  template.hasOutput('CloudFrontDomainName', {})

  // Verify outputs are exported for cross-stack references
  template.hasOutput('ImageStorageBucketName', {
    Export: {
      Name: 'ShloImageStorageBucketName',
    },
  })
})
