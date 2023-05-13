provider "aws" {
  region = var.aws_region
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

resource "random_pet" "suffix" {}

resource "aws_s3_bucket" "jenkins" {
  bucket = "fibonacci-${random_pet.suffix.id}"
}

resource "aws_s3_bucket_versioning" "jenkins" {
  bucket = aws_s3_bucket.jenkins.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "jenkins" {
  bucket = aws_s3_bucket.jenkins.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "jenkins" {
  depends_on = [aws_s3_bucket_ownership_controls.jenkins]

  bucket = aws_s3_bucket.jenkins.id
  acl    = "private"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "jenkins" {
  name               = "jenkins"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "jenkins" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateNetworkInterfacePermission"]
    resources = ["arn:aws:ec2:${var.aws_region}:${local.account_id}:network-interface/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:Subnet"

      values = [
        "arn:aws:ec2:us-east-2:187871168870:subnet/subnet-c91751a1",
        "arn:aws:ec2:us-east-2:187871168870:subnet/subnet-4e368a34"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.jenkins.arn,
      "${aws_s3_bucket.jenkins.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "jenkins" {
  role   = aws_iam_role.jenkins.name
  policy = data.aws_iam_policy_document.jenkins.json
}

resource "aws_codebuild_project" "jenkins" {
  name          = "fibonacci-project"
  description   = "Fibonaccion app codebuild project"
  build_timeout = "5"
  service_role  = aws_iam_role.jenkins.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.jenkins.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.jenkins.id}/build-log"
    }
  }

  source {
    type            = "GITHUB"
    location        = var.repository
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "master"

  vpc_config {
    vpc_id = var.vpc_id

    subnets = var.subnets

    security_group_ids = var.security_groups_ids
  }

  tags = {
    Environment = "Dev"
  }
}

data "aws_iam_policy_document" "code_deploy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "code_deploy" {
  name               = "code-deploy"
  assume_role_policy = data.aws_iam_policy_document.code_deploy.json
}

# resource "aws_iam_role_policy" "code_deploy" {
#   role   = aws_iam_role.code_deploy.name
#   policy = data.aws_iam_policy_document.code_deploy.json
# }

resource "aws_codedeploy_app" "jenkins" {
  compute_platform = "Lambda"
  name             = aws_codebuild_project.jenkins.name
}

resource "aws_codedeploy_deployment_group" "jenkins" {
  app_name              = aws_codebuild_project.jenkins.name
  deployment_group_name = aws_codedeploy_app.jenkins.name

  service_role_arn = aws_iam_role.code_deploy.arn

  deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce"

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
}
  