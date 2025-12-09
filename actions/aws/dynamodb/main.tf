resource "aws_dynamodb_table" "customers" {
  name     = var.table_name
  hash_key = "CustomerID"

  attribute {
    name = "CustomerID"
    type = "S"
  }

  # attribute {
  #   name = "Country"
  #   type = "S"
  # }

  # global_secondary_index {
  #   name            = "CountryIndex"
  #   projection_type = "ALL"
  #   hash_key        = "Country"
  # }

  billing_mode = "PAY_PER_REQUEST"

  lifecycle {
    action_trigger {
      actions = [action.aws_dynamodb_create_backup.safety]
      events  = [before_update]
    }
  }
}

action "aws_dynamodb_create_backup" "safety" {
  config {
    table_name  = var.table_name
    backup_name = "terraform-backup-${var.table_name}-${formatdate("YYYY-MM-DD_hhmmss", timestamp())}"
  }
}
