import * as cdk from 'aws-cdk-lib'
import * as s3 from 'aws-cdk-lib/aws-s3'
import * as lambda from 'aws-cdk-lib/aws-lambda'
import * as iam from 'aws-cdk-lib/aws-iam'
import { Construct } from 'constructs'

export class ShloInfraStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props)

    // Example: S3 bucket for storing assets
    const assetsBucket = new s3.Bucket(this, 'AssetsBucket', {
      bucketName: `shlo-assets-${cdk.Stack.of(this).account}-${
        cdk.Stack.of(this).region
      }`,
      versioned: true,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // Change to RETAIN for production
      autoDeleteObjects: true, // Only for development
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
    })

    // Example: Lambda function
    const exampleLambda = new lambda.Function(this, 'ExampleLambda', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        exports.handler = async (event) => {
          console.log('Event:', JSON.stringify(event, null, 2));
          return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Hello from Lambda!' })
          };
        };
      `),
      environment: {
        BUCKET_NAME: assetsBucket.bucketName,
      },
    })

    // Grant Lambda permissions to read from S3 bucket
    assetsBucket.grantRead(exampleLambda)

    // Outputs
    new cdk.CfnOutput(this, 'BucketName', {
      value: assetsBucket.bucketName,
      description: 'Name of the S3 bucket',
    })

    new cdk.CfnOutput(this, 'LambdaFunctionArn', {
      value: exampleLambda.functionArn,
      description: 'ARN of the Lambda function',
    })
  }
}
