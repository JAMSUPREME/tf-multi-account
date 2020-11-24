// This rule receives promotion and triggers builds in the current env

resource "aws_cloudwatch_event_rule" "receive_promotion" {
  count     = var.lower_environment_account_number == "" ? 0 : 1
  name        = "receive-promotion"
  description = "Receives promotion event from lower environment"

  event_pattern = templatefile("cloudwatch_receive_promotion.tpl.json", {
    lower_environment_account_number = var.lower_environment_account_number
  })
}

// TODO: also trigger a code build
resource "aws_cloudwatch_event_target" "receive_promotion_target_email" {
  count     = var.lower_environment_account_number == "" ? 0 : 1
  rule      = aws_cloudwatch_event_rule.receive_promotion[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.build_emailer.arn
}