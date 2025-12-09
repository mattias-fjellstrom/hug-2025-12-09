output "url" {
  value = "https://${aws_cloudfront_distribution.default.domain_name}"
}
