resource "aws_s3_bucket" "input" {
  bucket_prefix = "input"

  force_destroy = true
}

resource "aws_s3_bucket" "output" {
  bucket_prefix = "output"

  force_destroy = true
}

locals {
  path      = "audio"
  filenames = fileset(local.path, "*")
  files = {
    for filename in local.filenames : filename => {
      path         = "${local.path}/${filename}"
      display_name = split(".", basename(filename))[0]
    }
  }

  now = formatdate("YYYYMMDD-hhmmss", timestamp())
}

resource "aws_s3_object" "input" {
  for_each = local.files

  bucket         = aws_s3_bucket.input.bucket
  key            = each.value.path
  content_base64 = filebase64(each.value.path)

  lifecycle {
    action_trigger {
      actions = [action.aws_transcribe_start_transcription_job.input[each.key]]
      events  = [after_create, after_update]
    }
  }
}

action "aws_transcribe_start_transcription_job" "input" {
  for_each = local.files

  config {
    transcription_job_name = "${each.value.display_name}-${local.now}"
    media_file_uri         = "s3://${aws_s3_bucket.input.bucket}/${each.value.path}"
    identify_language      = true

    output_bucket_name = aws_s3_bucket.output.bucket
    output_key         = "transcripts/${each.value.display_name}-${local.now}.json"
  }
}
