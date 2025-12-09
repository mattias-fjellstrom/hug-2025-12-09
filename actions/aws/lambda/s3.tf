resource "aws_s3_bucket" "backups" {
  bucket_prefix = "backups"

  tags = {
    Owner = "Mattias"
  }

  lifecycle {
    action_trigger {
      actions = [action.aws_lambda_invoke.s3_created]
      events  = [after_update, after_create]
    }
  }
}
