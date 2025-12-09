#---------------------------------------------------------------------------------------------------
# EC2 ACTIONS
#---------------------------------------------------------------------------------------------------
action "aws_lambda_invoke" "ec2_created" {
  for_each = local.servers

  config {
    function_name = "terraform-actions-slack"

    payload = jsonencode({
      blocks = [
        {
          type = "section",
          text = {
            type = "mrkdwn",
            text = <<-MRKDWN
              :ec2: AWS EC2 was *created*!
              
              *Instance ID*: ${aws_instance.servers[each.key].id}

              <https://${data.aws_region.current.region}.console.aws.amazon.com/ec2/v2/home?region=${data.aws_region.current.region}#InstanceDetails:instanceId=${aws_instance.servers[each.key].id}|View in console ⤴>
            MRKDWN
          }
        }
      ]
    })
  }
}

action "aws_lambda_invoke" "ec2_updated" {
  for_each = local.servers

  config {
    function_name = "terraform-actions-slack"

    payload = jsonencode({
      blocks = [
        {
          type = "section",
          text = {
            type = "mrkdwn",
            text = <<-MRKDWN
              :ec2: An AWS EC2 instance was *updated*!
              
              *Instance ID*: ${aws_instance.servers[each.key].id}

              <https://${data.aws_region.current.region}.console.aws.amazon.com/ec2/v2/home?region=${data.aws_region.current.region}#InstanceDetails:instanceId=${aws_instance.servers[each.key].id}|View in console ⤴>
            MRKDWN
          }
        }
      ]
    })
  }
}

#---------------------------------------------------------------------------------------------------
# DYNAMODB ACTIONS
#---------------------------------------------------------------------------------------------------
action "aws_lambda_invoke" "dynamodb_created" {
  config {
    function_name = "terraform-actions-slack"

    payload = jsonencode({
      blocks = [
        {
          type = "section",
          text = {
            type = "mrkdwn",
            text = <<-MRKDWN
              :dynamodb: AWS DynamoDB table was *created*!
              
              *Table name*: ${aws_dynamodb_table.unicorns.name}

              <https://${data.aws_region.current.region}.console.aws.amazon.com/dynamodb/home?region=${data.aws_region.current.region}#tables:selected=${aws_dynamodb_table.unicorns.name}|View in console ⤴>
            MRKDWN
          }
        }
      ]
    })
  }
}

#---------------------------------------------------------------------------------------------------
# S3 ACTIONS
#---------------------------------------------------------------------------------------------------
action "aws_lambda_invoke" "s3_created" {
  config {
    function_name = "terraform-actions-slack"

    payload = jsonencode({
      blocks = [
        {
          type = "section",
          text = {
            type = "mrkdwn",
            text = <<-MRKDWN
              :s3: AWS S3 bucket was *created*!
              
              *Bucket name*: ${aws_s3_bucket.backups.bucket}

              <https://${data.aws_region.current.region}.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.backups.bucket}?region=${data.aws_region.current.region}&tab=objects|View in console ⤴>
            MRKDWN
          }
        }
      ]
    })
  }
}

#---------------------------------------------------------------------------------------------------
# AD HOC ACTIONS
#---------------------------------------------------------------------------------------------------
action "aws_lambda_invoke" "ad_hoc" {
  config {
    function_name = "terraform-actions-slack"

    payload = jsonencode({
      blocks = [
        {
          type = "section",
          text = {
            type = "mrkdwn",
            text = "👋 Ad-hoc action triggered!"
          }
        }
      ]
    })
  }
}
