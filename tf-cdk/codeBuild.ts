import { TerraformStack } from 'cdktf';
import { IamRole, IamRolePolicy } from './.gen/providers/aws'

export function appendCodeBuildResources(stack: TerraformStack){
  const cdkRole = new IamRole(stack, 'cdkCodeBuildRole', {
    name: 'cdk_docker_builder',
    assumeRolePolicy: `{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "codebuild.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }`
  });

  new IamRolePolicy(stack, 'cdkCodeBuildRolePolicy', {
    name: 'cdk-docker-codebuild-policy',
    // Note that under the hood this will generate "${aws_iam_role.cdkCodeBuildRole.name}"
    // so it is also possible to use the raw interpolation value and we can effectively grab a value from our "vanilla Terraform" resources
    // or vice versa
    role: cdkRole.name,
    policy: `{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Resource": [
            "*"
          ],
          "Action": [
            "logs:*",
            "s3:*",
            "ec2:*",
            "ecr:*"
          ]
        }
      ]
    }`
  });
}