locals {
  // When creating an SNS policy, we must use the root ARN
  lower_environment_account_arn = "arn:aws:iam::${var.lower_environment_account_number}:root"
}

// The lower environment will push its build success notification
// to this topic, and from there we will trigger a build
resource "aws_sns_topic" "build_trigger_topic" {
  name = "app_build_trigger"
  tags = local.global_tags
}

resource "aws_sns_topic_policy" "default" {
  count  = var.lower_environment_account_number == "" ? 0 : 1
  arn    = aws_sns_topic.build_trigger_topic.arn

  policy = templatefile("sns_policy.tpl.json", {
    topic_arn = aws_sns_topic.build_trigger_topic.arn,
    account_number = var.account_number,
    lower_environment_account_arn = local.lower_environment_account_arn
  })
}