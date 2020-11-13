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
        "ec2:*"
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
  }

  // logs_config {
  //   cloudwatch_logs {
  //     group_name  = "log-group"
  //     stream_name = "log-stream"
  //   }

  //   s3_logs {
  //     status   = "ENABLED"
  //     location = "${aws_s3_bucket.example.id}/build-log"
  //   }
  // }

  source {
    type            = "GITHUB"
    location        = "https://github.com/JAMSUPREME/tf-multi-account.git"
    git_clone_depth = 1

    // auth {
    //   type = "OAUTH"
    //   resource = var.github_token
    // }
  }

  // source_version = "main"

  // vpc_config {
  //   vpc_id = aws_vpc.example.id

  //   subnets = [
  //     aws_subnet.example1.id,
  //     aws_subnet.example2.id,
  //   ]

  //   security_group_ids = [
  //     aws_security_group.example1.id,
  //     aws_security_group.example2.id,
  //   ]
  // }

  tags = local.global_tags
}

resource "aws_codebuild_source_credential" "docker_builder_auth" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}