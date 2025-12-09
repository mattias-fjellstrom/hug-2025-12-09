terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.23"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

locals {
  servers = {
    "server-1" = {
      name = "Alice"
      ssh  = true
    }
    "server-2" = {
      name = "Bob"
      ssh  = false
    }
    "server-3" = {
      name = "Charlie"
      ssh  = false
    }
    "server-4" = {
      name = "Diana"
      ssh  = true
    }
  }
}

data "aws_region" "current" {}

data "aws_ami" "ubuntu" {
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  most_recent = true
}

resource "aws_s3_bucket" "backups" {
  bucket_prefix = "backups"

  lifecycle {
    action_trigger {
      actions = [action.aws_lambda_invoke.s3_created]
      events  = [after_create]
    }
  }
}

resource "aws_instance" "servers" {
  for_each = local.servers

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name      = "Instance ${each.value.name}"
    ManagedBy = "Terraform"
  }

  lifecycle {
    action_trigger {
      actions   = [action.aws_lambda_invoke.ec2_created[each.key]]
      events    = [after_create]
      condition = each.value.ssh
    }

    action_trigger {
      actions   = [action.aws_lambda_invoke.ec2_updated[each.key]]
      events    = [after_update]
      condition = each.value.ssh
    }
  }
}

resource "aws_dynamodb_table" "unicorns" {
  name     = "unicorns"
  hash_key = "UnicornID"

  attribute {
    name = "UnicornID"
    type = "S"
  }

  billing_mode = "PAY_PER_REQUEST"

  lifecycle {
    action_trigger {
      actions = [action.aws_lambda_invoke.dynamodb_created]
      events  = [after_create]
    }
  }
}
