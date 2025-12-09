data "aws_region" "current" {}

action "aws_lambda_invoke" "region" {
  config {
    function_name = "terraform-actions-slack"

    payload = jsonencode({
      blocks = [
        {
          type = "section",
          text = {
            type = "mrkdwn",
            text = "Currently executing in region ${data.aws_region.current.region}"
          }
        }
      ]
    })
  }
}

data "aws_instances" "all" {}

action "aws_lambda_invoke" "instances" {
  config {
    function_name = "terraform-actions-slack"

    payload = jsonencode({
      blocks = [
        {
          type = "section",
          text = {
            type = "mrkdwn",
            text = templatefile("${path.module}/templates/instances.tftmpl", {
              region    = data.aws_region.current.region
              instances = data.aws_instances.all.ids
            })
          }
        }
      ]
    })
  }
}

data "aws_route53_zones" "all" {}

data "aws_route53_zone" "all" {
  for_each = toset(data.aws_route53_zones.all.ids)
  zone_id  = each.value
}

locals {
  zones = { for zone in data.aws_route53_zone.all : zone.id => zone.name }
}

action "aws_lambda_invoke" "zones" {
  config {
    function_name = "terraform-actions-slack"

    payload = jsonencode({
      blocks = [
        {
          type = "section",
          text = {
            type = "mrkdwn",
            text = templatefile("${path.module}/templates/zones.tftmpl", {
              zones = local.zones
            })
          }
        }
      ]
    })
  }
}
