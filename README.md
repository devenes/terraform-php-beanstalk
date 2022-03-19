# PHP Elastic Beanstalk Deployment with Terraform

## Getting Started with the Sources

Terraform is a tool for building and managing infrastructure as code. It is a declarative,
programmatic, and portable way to create, destroy, and update infrastructure.

It helps us to define S3 Buckets, IAM Roles, EC2 Instances, and more.
We use S3 Buckets to store our application code files.
And we use IAM Roles to give permissions to our EC2 Instances.

Elastic Beanstalk is a service that makes it easy to deploy, manage, and scale
applications on Amazon's Elastic Cloud Compute Service.

Elastic Beanstalk creates the application environment with code stored in S3 buckets and makes it run on EC2 instances as application environments.

- You need to create an IAM role for the application. You can create an IAM role by following the instructions in the [AWS IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) section of the AWS IAM User Guide. IAM roles are used to authorize Terraform's operations. IAM role you create for this operations should have the S3, EC2, Elastic Beanstalk permissions.

After you create IAM user and policy you need to get its access key and secret key. And define them in GitHub Secrets as the environment variables. Replace your access key and secret key with your own access key and secret key with the following format:

```
AWS_ACCESS_KEY_ID
```

```
AWS_SECRET_ACCESS_KEY
```

## AWS Elastic Beanstalk

Add the existing Security Group to your AWS Elastic Beanstalk environment to allow access to the Elastic Beanstalk environment and the instances in the environment.

```
  setting {
    namespace = "aws:autoscaling:launchconfiguration" # Define namespace for environment settings
    name      = "SecurityGroups"                      # Define name of the environment setting
    value     = "devsec"                              # Define name of the security group to be used
  }
```

## SSHSourceRestriction

Used to lock down SSH access to an environment. For example, you can lock down SSH access to the EC2 instances so that only a bastion host can access the instances in the private subnet.

This string takes the following form:

`protocol`, `fromPort`, `toPort`, `source_restriction`

- `protocol`

  - The protocol for the ingress rule.

- `fromPort`

  - The starting port number.

- `toPort`

  - The ending port number.

- `source_restriction`

  - The CIDR range or the name of a security group that traffic must route through.. To specify a security group from another account (EC2-Classic only, must be in the same Region), include the account ID before the security group name. Use the following format:
    `other_account_id`/`security_group_name`

If you use Amazon Virtual Private Cloud (Amazon VPC) with Elastic Beanstalk so that your instances are launched within a virtual private cloud (VPC), specify a security group ID instead of a security group name.

Example: `tcp, 22, 22, 54.240.196.185/32`

Example: `tcp, 22, 22, my-security-group`

Example (EC2-Classic): `tcp, 22, 22, 123456789012/their-security-group`

Example (VPC): `tcp, 22, 22, sg-903004f8`

- Note: We don't create a new VPC in this template, so you don't need to specify the VPC ID and Security Group ID.

## Configure SSH access to the Elastic Beanstalk environment:

```
  setting {
    namespace = "aws:autoscaling:launchconfiguration" # Define namespace for environment settings
    name      = "SSHSourceRestriction"                # Define name of the environment setting
    value     = "tcp, 22, 22, 0.0.0.0/0"              # Define value of the environment setting
  }
```

## Define Solution Stack

You need to define your application version number and platform operating system version number on AWS that you want to use for deployment under `aws_elastic_beanstalk_environment` source section in main Terraform file called `main.tf` in this project.

- Deployment fails in Terraform stages when you type a value for `solution_stack_name` if it is not valid or not supported in Amazon Web Services (AWS).

- For example, if you type `64bit Amazon Linux 2 running PHP 8.0` for `solution_stack_name` in `aws_elastic_beanstalk_environment` source section in main Terraform file called `main.tf` in this project, Terraform will fail in stages.

```
solution_stack_name = "64bit Amazon Linux 2 v3.3.11 running PHP 8.0"
description = "environment for web app"
```

## Automate Terraform Deployment with GitHub Actions

When you create GitHub Action workflow, you can run `terraform apply` and `terraform destroy` stages automatically by pushing your code to GitHub repository. You can seperate stages with adding the following commands to your GitHub Action workflow:

You will be able to run `terraform apply` command when you push your code to the `main` branch:

```
- name: Terraform Apply
  if: github.ref == 'refs/heads/main'
  id: apply
  run: terraform apply
```

You will be able to run `terraform destroy` command when you push your code to the `destroy` branch:

```
- name: Terraform destroy
  if: github.ref == 'refs/heads/destroy'
  id: destroy
  run: terraform destroy
```

## Define Terraform stages in GitHub Actions workflow:

```
steps:
    - uses: actions/checkout@v2
    - uses: hashicorp/setup-terraform@v1
    with:
        terraform_wrapper: false
    - name: Terraform Init
    id: init
    run: |
        rm -rf .terraform
        terraform init
    - name: Terraform Plan
    id: plan
    run: terraform plan
    - name: Terraform Apply
    if: github.ref == 'refs/heads/main'
    id: apply
    run: terraform apply -auto-approve
    - name: Terraform destroy
    if: github.ref == 'refs/heads/destroy'
    id: destroy
    run: terraform destroy -auto-approve
```

```

```
