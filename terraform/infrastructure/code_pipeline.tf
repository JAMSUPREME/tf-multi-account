
// 
// For now omitting CodePipeline altogether for a few reasons:
// 1) Redundant SOURCE setup is required
// 2) Haven't yet figure out how I want to chain build steps together
// 

// resource "aws_codepipeline" "codepipeline" {
//   name     = "docker-builder"
//   role_arn = aws_iam_role.codepipeline_role.arn

//   // TODO: Figure out how to remove this?
//   artifact_store {
//     location = aws_s3_bucket.codepipeline_bucket.bucket
//     type     = "S3"
//   }

//   stage {
//     name = "Source"

//     // NOTE: This seems redundant when we've configured it in codebuild?
//     action {
//       name             = "Source"
//       category         = "Source"
//       owner            = "ThirdParty"
//       provider         = "GitHub"
//       version          = "1"
//       output_artifacts = ["source_output"]

//       configuration = {
//         Owner      = "jamsupreme"
//         Repo       = "tf-multi-account"
//         Branch     = "main"
//         OAuthToken = var.github_token
//       }
//     }
//   }

//   stage {
//     name = "Build"

//     action {
//       name             = "Build"
//       category         = "Build"
//       owner            = "AWS"
//       provider         = "CodeBuild"
//       input_artifacts  = ["source_output"]
//       output_artifacts = ["build_output"]
//       version          = "1"

//       configuration = {
//         ProjectName = aws_codebuild_project.docker_builder.name
//       }
//     }
//   }

//   stage {
//     name = "Deploy"

//     action {
//       name            = "Deploy"
//       category        = "Deploy"
//       owner           = "AWS"
//       provider        = "CloudFormation"
//       input_artifacts = ["build_output"]
//       version         = "1"

//       configuration = {
//         ActionMode     = "REPLACE_ON_FAILURE"
//         Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
//         OutputFileName = "CreateStackOutput.json"
//         StackName      = "MyStack"
//         TemplatePath   = "build_output::sam-templated.yaml"
//       }
//     }
//   }
// }

// resource "aws_s3_bucket" "codepipeline_bucket" {
//   bucket = "infra-${var.deploy_env}-terraform-${var.account_number}"
//   acl    = "private"
// }

// resource "aws_iam_role" "codepipeline_role" {
//   name = "test-role"

//   assume_role_policy = <<EOF
// {
//   "Version": "2012-10-17",
//   "Statement": [
//     {
//       "Effect": "Allow",
//       "Principal": {
//         "Service": "codepipeline.amazonaws.com"
//       },
//       "Action": "sts:AssumeRole"
//     }
//   ]
// }
// EOF
// }

// resource "aws_iam_role_policy" "codepipeline_policy" {
//   name = "codepipeline_policy"
//   role = aws_iam_role.codepipeline_role.id

//   policy = <<EOF
// {
//   "Version": "2012-10-17",
//   "Statement": [
//     {
//       "Effect":"Allow",
//       "Action": [
//         "s3:GetObject",
//         "s3:GetObjectVersion",
//         "s3:GetBucketVersioning",
//         "s3:PutObject"
//       ],
//       "Resource": [
//         "${aws_s3_bucket.codepipeline_bucket.arn}",
//         "${aws_s3_bucket.codepipeline_bucket.arn}/*"
//       ]
//     },
//     {
//       "Effect": "Allow",
//       "Action": [
//         "codebuild:BatchGetBuilds",
//         "codebuild:StartBuild"
//       ],
//       "Resource": "*"
//     }
//   ]
// }
// EOF
// }
