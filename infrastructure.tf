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
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "alydar_user"
    value     = aws_iam_instance_profile.example_app_ec2_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "alydar_terraform_key"
  }
}

resource "aws_iam_instance_profile" "example_app_ec2_instance_profile" {
  name = "example_app_ec2_instance_profile"
  role = aws_iam_role.example_app_role.name
}

resource "aws_iam_role" "example_app_role" {
  name               = "example_app_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}