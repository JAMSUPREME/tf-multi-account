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

locals {
  global_tags = {
    "SourceRepo"  = "tf-multi-account"
    "Environment" = var.deploy_env
  }
}