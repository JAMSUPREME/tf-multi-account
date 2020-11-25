# This rule receives promotion and triggers builds in the current env

resource "aws_cloudwatch_event_rule" "receive_promotion" {
  count     = var.lower_environment_account_number == "" ? 0 : 1
  name        = "receive-promotion"
  description = "Receives promotion event from lower environment"

  event_pattern = templatefile("cloudwatch_receive_promotion.tpl.json", {
    lower_environment_account_number = var.lower_environment_account_number
  })
}

resource "aws_cloudwatch_event_target" "receive_promotion_target_email" {
  count     = var.lower_environment_account_number == "" ? 0 : 1
  rule      = aws_cloudwatch_event_rule.receive_promotion[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.build_emailer.arn
  input     = jsonencode(
    {
      receivedPromotion = "true",
      environment = var.deploy_env
    }
  )
}

resource "aws_cloudwatch_event_target" "receive_promotion_target_codebuild" {
  count     = var.lower_environment_account_number == "" ? 0 : 1
  rule      = aws_cloudwatch_event_rule.receive_promotion[0].name
  target_id = "TriggerCodeBuild"
  arn       = aws_codebuild_project.docker_builder.arn
  role_arn  = aws_iam_role.cloudwatch_to_codebuild.arn
}

#
# IAM
#
resource "aws_iam_role" "cloudwatch_to_codebuild" {
  name = "${var.deploy_env}-cloudwatch-to-codebuild"

  assume_role_policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "events.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY

  tags = local.global_tags
}

resource "aws_iam_role_policy" "cloudwatch_to_codebuild_policy" {
  name = "${var.deploy_env}-cloudwatch-to-codebuild-policy"
  role = aws_iam_role.cloudwatch_to_codebuild.name

  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Resource": [
          "${aws_codebuild_project.docker_builder.arn}"
        ],
        "Action": [
          "codebuild:StartBuild"
        ]
      }
    ]
  }
  POLICY
}