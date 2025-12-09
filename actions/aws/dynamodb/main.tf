resource "aws_dynamodb_table" "customers" {
  name     = var.table_name
  hash_key = "CustomerID"

  attribute {
    name = "CustomerID"
    type = "S"
  }

  tags = {
    Owner = "Mattias"
    Dummy = "true"
  }

  billing_mode = "PAY_PER_REQUEST"

  lifecycle {
    ignore_changes = [tags]

    action_trigger {
      actions = [
        action.aws_dynamodb_create_backup.safety,
        action.aws_lambda_invoke.notify,
      ]
      events = [before_update]
    }
  }
}

locals {
  backup_name = "terraform-backup-${var.table_name}-${formatdate("YYYY-MM-DD_hhmmss", timestamp())}"
}

action "aws_dynamodb_create_backup" "safety" {
  config {
    table_name  = var.table_name
    backup_name = local.backup_name
  }
}

action "aws_lambda_invoke" "notify" {
  config {
    function_name = "terraform-actions-slack"

    payload = jsonencode({
      blocks = [
        {
          type = "section",
          text = {
            type = "mrkdwn",
            text = ":dynamodb: DynamoDB table *${var.table_name}* was backed up before applying an update!"
          }
        }
      ]
    })
  }
}
