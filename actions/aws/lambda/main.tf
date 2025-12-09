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
      name   = "Alice"
      notify = true
    }
    "server-2" = {
      name   = "Bob"
      notify = false
    }
    "server-3" = {
      name   = "Charlie"
      notify = false
    }
    "server-4" = {
      name   = "Diana"
      notify = true
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
      condition = each.value.notify
    }

    action_trigger {
      actions   = [action.aws_lambda_invoke.ec2_updated[each.key]]
      events    = [after_update]
      condition = each.value.notify
    }
  }
}
