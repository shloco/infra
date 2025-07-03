#!/usr/bin/env node
import 'source-map-support/register'
import * as cdk from 'aws-cdk-lib'
import { ShloInfraStack } from '../lib/shlo-infra-stack'

const app = new cdk.App()

// Get environment from context or use defaults
const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION || 'us-east-2',
}

new ShloInfraStack(app, 'ShloInfraStack', {
  env,
  description: 'Shlo Infrastructure Stack',
})

app.synth()
