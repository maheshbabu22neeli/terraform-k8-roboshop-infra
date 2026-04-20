terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.33.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket       = "terrform-remote-state-dev"
    key          = "terraform-k8-roboshop-sg-rules.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # Enables S3 native locking
  }
}

provider "aws" {
  region = "us-east-1"
}