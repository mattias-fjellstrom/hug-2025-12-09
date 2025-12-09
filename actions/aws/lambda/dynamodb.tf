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
