resource "aws_ecr_repository" "my_repository" {
  name = "alydarecr"  # Name of the repository you want to create
}

resource "aws_elastic_beanstalk_application" "example_app" {
  name        = "alydar-task-listing-app"
  description = "Task listing app"
}

resource "aws_elastic_beanstalk_environment" "example_app_environment" {
  name                = "alydarEB"
  application         = aws_elastic_beanstalk_application.example_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
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
  acl    = "private"
}

# Set the ACL for the S3 bucket using the aws_s3_bucket_acl resource
resource "aws_s3_bucket_acl" "dockerrun_bucket_acl" {
  bucket = aws_s3_bucket.dockerrun_bucket.bucket
  acl    = "private"
}

# Upload the Dockerrun.aws.json file to the S3 bucket using the aws_s3_object resource
resource "aws_s3_object" "dockerrun_json" {
  bucket = aws_s3_bucket.dockerrun_bucket.bucket
  key    = "Dockerrun.aws.json"  # The key (file name) in the S3 bucket
  source = "Dockerrun.aws.json"  # Ensure the correct local path here
  acl    = "private"
}
