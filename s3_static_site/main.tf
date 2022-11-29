resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.domain_name}"
}

resource "aws_cloudfront_distribution" "distribution" {
  depends_on = [aws_cloudfront_distribution.oia]

  aliases         = [var.domain_name]
  comment         = "Distribution for ${var.domain_name}"
  enabled         = true
  is_ipv6_enabled = true

  default_root_object = var.default_root_object

  origin {
    domain_name = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.s3_bucket.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.s3_bucket.bucket_regional_domain_name

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  tags = var.tags  
}

resource "aws_route53_record" "record" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = var.tags
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  depends_on              = [aws_route53_record.certificate_validation]
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = aws_acm_certificate.certificate.domain_validation_options.*.resource_record_name
}

resource "aws_route53_record" "certificate_validation" {
  name    = aws_acm_certificate.certificate.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.certificate.domain_validation_options.0.resource_record_type
  zone_id = var.zone_id
  records = [aws_acm_certificate.certificate.domain_validation_options.0.resource_record_value]
  ttl     = 60
}