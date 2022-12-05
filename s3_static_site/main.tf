resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.domain_name}"
}

#tfsec:ignore:aws-cloudfront-enable-waf tfsec:ignore:aws-cloudfront-enable-logging
resource "aws_cloudfront_distribution" "distribution" {
  depends_on = [aws_cloudfront_origin_access_identity.oai]

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

    dynamic "lambda_function_association" {
      for_each = var.enable_lambda_edge_function ? [1] : []

      content {
        event_type   = "origin-request"
        include_body = false
        lambda_arn   = aws_lambda_function.lambda[0].qualified_arn
      }
    }

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
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
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = var.tags
}

# cloudfront security headers
resource "aws_cloudfront_response_headers_policy" "headers" {
  name    = "headers"
  comment = "Headers for ${var.domain_name}"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET"]
    }

    access_control_allow_origins {
      items = ["devsecopsdocs.com"]
    }

    origin_override = true
  }

  security_headers_config {
    strict_transport_security {
      include_subdomains = true
      preload            = true
      override           = true

      access_control_max_age_sec = 31536000
    }

    content_security_policy {
      override = true
      content_security_policy = "default-src 'self'; img-src 'self' imgs.xkcd.com data:; script-src 'self'; style-src 'self'; font-src 'self'; connect-src 'self';"
    }

    xss_protection {
      override = true
      mode_block = true
      protection = true
    }

    content_type_options {
      override = true
    }

    referrer_policy {
      override = true
      referrer_policy = "same-origin"
    }

    origin_override = true
  }
  
  custom_headers_config {
    items {
      header   = "X-Frame-Options"
      override = true
      value  = "DENY"
    }
  }
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

resource "aws_route53_record" "record_validation" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.record_validation : record.fqdn]
}