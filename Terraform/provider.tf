terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = ">= 2.0.0"
  }
}

provider "aws" {
  region = "us-west-2"
}
