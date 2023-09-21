################################
# メンテナンスページ用CloudFront
################################
resource "aws_cloudfront_distribution" "main" {
  comment             = "${var.project}-main-cf-${var.env}"
  enabled             = true
  # aliases             = [aws_acm_certificate.main.domain_name]
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  web_acl_id          = aws_wafv2_web_acl.main.arn
  origin {
    domain_name              = aws_s3_bucket.main.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
    origin_id                = aws_cloudfront_origin_access_control.main.name
  }
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_cloudfront_origin_access_control.main.name
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 3600
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
    # acm_certificate_arn      = aws_acm_certificate.main.arn
    # ssl_support_method       = "sni-only"
    # minimum_protocol_version = "TLSv1.2_2021"
  }
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }
  tags = {
    Name = "${var.project}-cf-main-${var.env}"
  }
  # depends_on = [
  #   aws_acm_certificate.main,
  #   aws_route53_record.main_cert_validation,
  #   aws_acm_certificate_validation.main_cert_validation
  # ]
}

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project}-main-oac-${var.env}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "no-override"
  signing_protocol                  = "sigv4"
  lifecycle {
    create_before_destroy = true
  }
}
