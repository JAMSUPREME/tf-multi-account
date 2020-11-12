variable "deploy_env" {
  type        = string
  description = "Deploy environment (dev, prod, test)"
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