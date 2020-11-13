provider "aws" {
  version = "~> 3"
  region  = "us-east-1"
  profile = "tf_multi_dev"
}

terraform {
  required_version = "~> 0.13"

  # All backend values must be supplied at init-time
  backend "s3" {
  }
}
