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

resource "aws_elastic_beanstalk_application" "example_app" {
  name        = "alydar-task-listing-app"
  description = "Task listing app"
}
resource "aws_elastic_beanstalk_environment" "example_app_environment" {
  name                = "alydar-task-listing-app-environment"
  application         = aws_elastic_beanstalk_application.example_app.name
  # This page lists the supported platforms
  # we can use for this argument:
  # https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "alydar_user"
    value     = aws_iam_instance_profile.example_app_ec2_instance_profile.name
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "EC2KeyName"
    value = "alydar_keypair"
  }
}