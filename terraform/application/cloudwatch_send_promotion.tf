data "aws_organizations_organization" "current_org" {}

resource "aws_cloudwatch_event_permission" "organization_access" {
  principal    = "*"
  statement_id = "OrganizationAccess"

  condition {
    key   = "aws:PrincipalOrgID"
    type  = "StringEquals"
    value = data.aws_organizations_organization.current_org.id
  }
}

resource "aws_cloudwatch_event_rule" "build_promotion" {
  name        = "build-promotion"
  description = "Promotes builds automatically to next environment"

  event_pattern = templatefile("cloudwatch_event_codebuild.tpl.json", {
    project_name = aws_codebuild_project.docker_builder.name
  })
}

# Send to the next environment's event bus
resource "aws_cloudwatch_event_target" "promotion_account_bus" {
  count     = var.build_promotion_event_bus_arn == "" ? 0 : 1
  rule      = aws_cloudwatch_event_rule.build_promotion.name
  target_id = "SendToHigherEnvironmentEventBus"
  arn       = var.build_promotion_event_bus_arn
  role_arn  = aws_iam_role.event_pusher.arn
}

# Email team of successful build
resource "aws_cloudwatch_event_target" "local_email" {
  rule      = aws_cloudwatch_event_rule.build_promotion.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.build_emailer.arn
  input     = jsonencode(
    {
      buildComplete = "true",
      environment = var.deploy_env
    }
  )
}
# TODO: add auto-subscription here?

#
# IAM
#
resource "aws_iam_role" "event_pusher" {
  name = "${var.deploy_env}-event-pusher"

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

resource "aws_iam_role_policy" "event_pusher_policy" {
  count  = var.build_promotion_event_bus_arn == "" ? 0 : 1
  name = "${var.deploy_env}-event-pusher-policy"
  role = aws_iam_role.event_pusher.name

  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Resource": [
          "${var.build_promotion_event_bus_arn}"
        ],
        "Action": [
          "events:PutEvents"
        ]
      }
    ]
  }
  POLICY
}