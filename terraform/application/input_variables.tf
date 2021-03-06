variable "profile" {
  type        = string
  description = "Local AWS profile to use for terraform apply"
}
variable "deploy_env" {
  type        = string
  description = "Deploy environment (dev, prod, test)"
}
variable "account_number" {
  type        = string
  description = "AWS account number. Primarily used for making unique s3 buckets"
}
variable "lower_environment_account_number" {
  type        = string
  description = "AWS account number of the lower environment. Allows lower environment to promote to current environment."
}
variable "github_token" {
  type        = string
  description = "github token for pulling code from github"
}
variable "docker_token" {
  type        = string
  description = "docker token for pulling images from docker (or you will get throttled)"
}


#
# Inputs with defaults
#
variable "build_promotion_event_bus_arn" {
  type        = string
  default     = ""
  description = "SNS topic ARN that will trigger a build in the subsequent environment."
}
variable "automatic_builds" {
  type        = bool
  default     = false
  description = "Whether or not builds are triggered automatically upon main branch commit. Generally reserved for dev"
}


locals {
  global_tags = {
    "SourceRepo"  = "tf-multi-account"
    "Environment" = var.deploy_env
  }
  cdk_sns_topic_name = "my-first-topic-vanilla"
}