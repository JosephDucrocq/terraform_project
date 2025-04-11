resource "aws_ecr_repository" "my_repository" {
  name = "alydarecr"  # Name of the repository you want to create
}
resource "aws_elastic_beanstalk_application" "example_app" {
  name        = "alydar-task-listing-app"
  description = "Task listing app"
}
# resource "aws_elastic_beanstalk_environment" "example_app_environment" {
#   name                = "name-EB"
#   application         = aws_elastic_beanstalk_application.example_app.name
#   solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"
#   setting {
#     namespace = "aws:autoscaling:launchconfiguration"
#     name      = "IamInstanceProfile"
#     value     = aws_iam_instance_profile.example_app_ec2_instance_profile.name
#   }
#   setting {
#     namespace = "aws:autoscaling:launchconfiguration"
#     name      = "EC2KeyName"
#     value     = "alydar_terraform_key"
#   }
# }
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
resource "aws_iam_role" "example_app_ec2_role" {
  name = "alydar-task-listing-app-ec2-instance-role"
  // Allows the EC2 instances in our EB environment to assume (take on) this
  // role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole"
            Principal = {
               Service = "ec2.amazonaws.com"
            }
            Effect = "Allow"
            Sid = ""
        }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "elastic_beanstalk_web_tier" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.example_app_ec2_role.name
}
resource "aws_iam_role_policy_attachment" "elastic_beanstalk_multicontainer_docker" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
  role       = aws_iam_role.example_app_ec2_role.name
}
resource "aws_iam_role_policy_attachment" "elastic_beanstalk_worker_tier" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
  role       = aws_iam_role.example_app_ec2_role.name
}
resource "aws_iam_role_policy_attachment" "example_app_ec2_role_policy_attachment" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
# Create an S3 bucket to store the Dockerrun.aws.json file
resource "aws_s3_bucket" "dockerrun_bucket" {
  bucket = "alydar-dockerrun-bucket"  # You can change this name as needed
}
# Create database
resource "aws_db_instance" "rds_app" {
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "15.7"
  instance_class       = "db.t3.micro"
  identifier           = "alydar"
  db_name              = "alydar_database"
  username             = "root"
  password             = "password"
  skip_final_snapshot  = true
  publicly_accessible = true
}
resource "aws_elastic_beanstalk_environment" "app_environment" {
  name                = "alydarEB"
  application         = "alydar-task-listing-app"
  environment_name    = "alydarEB"
  solution_stack_name = "64bit Amazon Linux 2 v3.3.6 running Node.js 14"
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = aws_db_instance.rds_app.endpoint  # Endpoint from RDS instance
  }

resource "aws_secretsmanager_secret" "db_password" {
  name        = "alydar-db-password-secret"  # Choose a unique name
  description = "Database password for Alydar app"
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    password = "alydar123!"  # Replace with your actual password or variable
  })
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
    value     = aws_db_instance.rds_app.db_name  # DB name from RDS instance
  }
  # DB_USER from aws_db_instance
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USER"
    value     = aws_db_instance.rds_app.username  # DB username from RDS instance
  }
  # DB_PASSWORD from a secret manager or SSM (not directly from RDS for security reasons)
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = data.aws_secretsmanager_secret.db_password.secret_string  # Use AWS Secrets Manager (preferred)
  }
}
  