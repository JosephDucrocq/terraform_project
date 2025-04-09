terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  backend "s3" {
    bucket = "alydar-bucket"
    key    = "alydar-bucket/dev/terraform.tfstate"
    region = "eu-west-2"
  }
required_version = ">= 1.2.0"
}
# AWS provider configuration
provider "aws" {
  region = "eu-west-2"
}

# Create an ECR repository
resource "aws_ecr_repository" "my_repository" {
  name = "alydarecr"  # Name of the repository you want to create
}

