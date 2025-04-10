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

resource "aws_elastic_beanstalk_environment" "app_environment" {
  name                = "alydarEB"
  application         = "alydar-task-listing-app"
  environment_name    = "alydarEB"
  solution_stack_name = "64bit Amazon Linux 2 v3.3.6 running Node.js 14"
  # DB_HOST from aws_db_instance
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = aws_db_instance.default.endpoint  # Endpoint from RDS instance
  }
  # DB_PORT from aws_db_instance
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PORT"
    value     = "5432"  # Default PostgreSQL port
  }
  # DB_NAME from aws_db_instance
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_NAME"
    value     = aws_db_instance.default.db_name  # DB name from RDS instance
  }
  # DB_USER from aws_db_instance
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USER"
    value     = aws_db_instance.default.username  # DB username from RDS instance
  }
  # DB_PASSWORD from a secret manager or SSM (not directly from RDS for security reasons)
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = data.aws_secretsmanager_secret.db_password.secret_string  # Use AWS Secrets Manager (preferred)
  }
}