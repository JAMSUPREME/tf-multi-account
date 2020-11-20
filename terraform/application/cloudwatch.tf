resource "aws_cloudwatch_event_rule" "build_promotion" {
  name        = "build-promotion"
  description = "Promotes builds automatically to next environment"

  event_pattern = templatefile("cloudwatch_event_codebuild.tpl.json", {
    project_name = aws_codebuild_project.docker_builder.name
  })
}

// Send to the next environment's SNS build topic
resource "aws_cloudwatch_event_target" "sns" {
  count     = var.build_promotion_sns_topic_arn == "" ? 0 : 1
  rule      = aws_cloudwatch_event_rule.build_promotion.name
  target_id = "SendToSNS"
  arn       = var.build_promotion_sns_topic_arn
}