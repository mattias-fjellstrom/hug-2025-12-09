resource "aws_s3_bucket" "default" {
  bucket_prefix = "website"
}

data "aws_iam_policy_document" "cloudfront" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = ["${aws_s3_bucket.default.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.default.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.default.bucket
  policy = data.aws_iam_policy_document.cloudfront.json
}

resource "aws_s3_object" "index_html" {
  bucket         = aws_s3_bucket.default.bucket
  key            = "index.html"
  content_type   = "text/html"
  content_base64 = filebase64("${path.module}/html/index.html")

  lifecycle {
    action_trigger {
      events  = [after_update]
      actions = [action.aws_cloudfront_create_invalidation.update]
    }
  }
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "default"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "default" {
  origin {
    domain_name              = aws_s3_bucket.default.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = "default"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "default"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 120
    max_ttl     = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

action "aws_cloudfront_create_invalidation" "update" {
  config {
    distribution_id = aws_cloudfront_distribution.default.id
    paths           = ["/*"]
  }
}
