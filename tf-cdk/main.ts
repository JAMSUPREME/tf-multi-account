import { Construct } from 'constructs';
import { App, TerraformStack, TerraformLocal } from 'cdktf';
import { S3Backend } from 'cdktf';
// import { RemoteBackend } from 'cdktf';
import { AwsProvider, SnsTopic } from './.gen/providers/aws'
import { appendCodeBuildResources } from './codeBuild'


// 
// NOTE: if using this purely for synthesis, I think provider and backend could be omitted,
// and then the resulting JSON just dumped into the /terraform directory
// 

class MyStack extends TerraformStack {
  constructor(scope: Construct, name: string, hybrid: boolean) {
    super(scope, name);

    if(!hybrid){
      new AwsProvider(this, 'aws', {
        region: 'us-east-1',
        profile: 'tf_multi_dev'
      });
      new S3Backend(this, {
        bucket: "tfmulti-dev-cdk-813871934424",
        key: "terraform.tfstate",
        region: "us-east-1"
      });
      new TerraformLocal(this, 'cdk_sns_topic_name', 'my-first-topic');
    }

    // Note: I'm using TF interpolation here instead of a variable to see if it would work in a hybrid setup
    new SnsTopic(this, 'myFirstTopic', {
      name: '${local.cdk_sns_topic_name}',
      displayName: 'first-topic-displayy'
    });

    appendCodeBuildResources(this);
  }
}

const app = new App();
new MyStack(app, 'tf-cdk', true);

// TODO: replace this with an s3 backend
// new RemoteBackend(stack, {
//   hostname: 'app.terraform.io',
//   organization: 'jspencer-jms',
//   workspaces: {
//     name: 'typescript'
//   }
// });

// moved this into the stack itself to be consistent
// new S3Backend(stack, {
//   bucket: "tfmulti-dev-cdk-813871934424",
//   key: "terraform.tfstate",
//   region: "us-east-1"
// });


app.synth();