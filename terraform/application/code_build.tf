resource "aws_iam_role" "docker_builder" {
  name = "docker_builder"

  assume_role_policy = <<EOF
{
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
}
EOF
}

resource "aws_iam_role_policy" "docker_builder_policy" {
  name = "${var.deploy_env}-docker-codebuild-policy"
  role = aws_iam_role.docker_builder.name

  policy = <<POLICY
{
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
}
POLICY
}

resource "aws_codebuild_project" "docker_builder" {
  name          = "docker-builder"
  description   = "Builds docker images"
  build_timeout = "5"
  service_role  = aws_iam_role.docker_builder.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ECR_ID"
      value = aws_ecr_repository.main_ecr.repository_url
    }
  }

  // NOTE: Probably want to wire up cloudwatch later
  // logs_config {
  //   cloudwatch_logs {
  //     group_name  = "log-group"
  //     stream_name = "log-stream"
  //   }
  // }

  source {
    type            = "GITHUB"
    location        = "https://github.com/JAMSUPREME/tf-multi-account.git"
    git_clone_depth = 1
  }

  tags = local.global_tags
}

resource "aws_codebuild_source_credential" "docker_builder_auth" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}

// Add webhook so builds get trigger automatically
resource "aws_codebuild_webhook" "docker_builder_webhook" {
  project_name = aws_codebuild_project.docker_builder.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "main"
    }
  }
}