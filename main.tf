terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # required
      version = "~> 3.27"       # required
    }
  }

  backend "s3" {
    bucket = "myapp-mybucket" # S3 bucket name
    key    = "path/to/my/key" # S3 key name
    region = "us-east-2"      # S3 region
  }
}

# AWS Provider configuration
provider "aws" {
  profile = "default"   # AWS profile 
  region  = "us-east-2" # AWS region
}

# Create S3 bucket for PHP web app
resource "aws_s3_bucket" "eb_bucket" {
  bucket = "enes-eb-PHP-web" # Name of S3 bucket to create for web app deployment needs to be unique 
}

# Define App files to be uploaded to S3
resource "aws_s3_bucket_object" "eb_bucket_obj" {
  bucket = aws_s3_bucket.eb_bucket.id # Name of S3 bucket to upload files to
  key    = "beanstalk/php-web.zip"    # S3 Bucket path to upload app files
  source = "php-web.zip"              # Name of the file on GitHub repo to upload to S3
}

# Define Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = "enes-eb-tf-app" # Name of the Elastic Beanstalk application
  description = "simple php app" # Description of the Elastic Beanstalk application
}

# Create Elastic Beanstalk environment for application with defining environment settings
resource "aws_elastic_beanstalk_application_version" "eb_app_ver" {
  bucket      = aws_s3_bucket.eb_bucket.id                    # S3 bucket name
  key         = aws_s3_bucket_object.eb_bucket_obj.id         # S3 key path 
  application = aws_elastic_beanstalk_application.eb_app.name # Elastic Beanstalk application name
  name        = "enes-eb-tf-app-version-lable"                # Version label for Elastic Beanstalk application
}

resource "aws_elastic_beanstalk_environment" "tfenv" {
  name                = "enes-eb-tf-env"                                          # Name of the Elastic Beanstalk environment
  application         = aws_elastic_beanstalk_application.eb_app.name             # Elastic Beanstalk application name
  solution_stack_name = "^64bit Amazon Linux (.*) running PHP 8.0$"               # Define current version of the platform
  description         = "environment for web app"                                 # Define environment description
  version_label       = aws_elastic_beanstalk_application_version.eb_app_ver.name # Define version label

  setting {
    namespace = "aws:autoscaling:launchconfiguration" # Define namespace
    name      = "IamInstanceProfile"                  # Define name
    value     = "aws-elasticbeanstalk-ec2-role"       # Define value
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration" # Define namespace
    name      = "EC2KeyName"                          # Define name
    value     = "ssh1"                                # Define your keypair name
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration" # Define namespace
    name      = "InstanceType"                        # Define name
    value     = "t2.micro"                            # Define instance type
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration" # Define namespace
    name      = "SecurityGroups"                      # Define name
    value     = "sg-0ca128398dc1ae28a"                # Define security group
  }
}
