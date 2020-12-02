import { Construct } from 'constructs';
import { App, TerraformStack } from 'cdktf';
import { S3Backend } from 'cdktf';
// import { RemoteBackend } from 'cdktf';
import { AwsProvider, SnsTopic } from './.gen/providers/aws'

class MyStack extends TerraformStack {
  constructor(scope: Construct, name: string) {
    super(scope, name);

    // define resources here

    new AwsProvider(this, 'aws', {
      region: 'us-east-1',
      profile: 'tf_multi_dev'
    });

    // strangely, displayName doesn't seem to get picked up correctly. It must be explicitly overridden.
    new SnsTopic(this, 'Topic', {
      name: 'my-first-topic',
      displayName: 'first-topic-displayy'
    });
  }
}

const app = new App();
const stack = new MyStack(app, 'tf-cdk');

// TODO: replace this with an s3 backend
// new RemoteBackend(stack, {
//   hostname: 'app.terraform.io',
//   organization: 'jspencer-jms',
//   workspaces: {
//     name: 'typescript'
//   }
// });

new S3Backend(stack, {
  bucket: "tfmulti-dev-cdk-813871934424",
  key: "terraform.tfstate",
  region: "us-east-1"
});


app.synth();