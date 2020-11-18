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
variable "github_token" {
  type        = string
  description = "github token for pulling code from github"
}
variable "docker_token" {
  type        = string
  description = "docker token for pulling images from docker (or you will get throttled)"
}

locals {
  global_tags = {
    "SourceRepo"  = "tf-multi-account"
    "Environment" = var.deploy_env
  }
}