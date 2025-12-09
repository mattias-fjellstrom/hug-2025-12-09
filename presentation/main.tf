terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_s3_bucket" "demo" {
  bucket_prefix = "demo"

  tags = {
    ManagedBy = "terraform"
    Owner     = "HUG"
  }
}

action "aws_lambda_invoke" "test" {
  config {
    function_name   = ""
    invocation_type = "RequestResponse"
    payload         = <<-EOF
    EOF
  }
}
