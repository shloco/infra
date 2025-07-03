import { Template } from 'aws-cdk-lib/assertions'
import * as cdk from 'aws-cdk-lib'
import { ShloInfraStack } from '../lib/shlo-infra-stack'

test('S3 Bucket Created', () => {
  const app = new cdk.App()
  const stack = new ShloInfraStack(app, 'TestStack')
  const template = Template.fromStack(stack)

  template.hasResourceProperties('AWS::S3::Bucket', {
    VersioningConfiguration: {
      Status: 'Enabled',
    },
  })
})

test('Lambda Function Created', () => {
  const app = new cdk.App()
  const stack = new ShloInfraStack(app, 'TestStack')
  const template = Template.fromStack(stack)

  template.hasResourceProperties('AWS::Lambda::Function', {
    Runtime: 'nodejs20.x',
  })
})

test('Stack has outputs', () => {
  const app = new cdk.App()
  const stack = new ShloInfraStack(app, 'TestStack')
  const template = Template.fromStack(stack)

  template.hasOutput('BucketName', {})
  template.hasOutput('LambdaFunctionArn', {})
})
