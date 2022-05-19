terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
    random = {
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.0"
    }
  }
}

provider "aws" {
  region  = "af-south-1"
  profile = "personal"
  shared_credentials_file = "~/.aws/credentials"
}

provider "random" {}
