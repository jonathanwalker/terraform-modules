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

  dynamic "origin" {
    for_each = var.enable_plausible_analytics ? [1] : []
    content {
      domain_name = "plausible.io"
      origin_id   = "plausible.io"

      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_keepalive_timeout = 5
        origin_read_timeout      = 30
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.enable_plausible_analytics ? [1] : []
    content {
      path_pattern     = "/js/script.js"
      target_origin_id = "plausible.io"

      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]

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
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.enable_plausible_analytics ? [1] : []
    content {
      path_pattern     = "/api/event"
      target_origin_id = "plausible.io"

      allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]

      forwarded_values {
        query_string = true

        cookies {
          forward = "none"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 3600
      max_ttl                = 86400
    }
  }

  # Custom error response
  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = var.error_page
  }
  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = var.error_page
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.s3_bucket.bucket_regional_domain_name

    response_headers_policy_id = aws_cloudfront_response_headers_policy.headers.id

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

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/404.html"
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = "/404.html"
  }

  tags = var.tags
}

# cloudfront security headers
resource "aws_cloudfront_response_headers_policy" "headers" {
  name    = "${replace(var.domain_name, ".", "-")}-headers" 
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

      access_control_max_age_sec = var.access_control_max_age_sec
    }

    content_security_policy {
      override                = true
      content_security_policy = var.content_security_policy
    }

    xss_protection {
      override   = true
      mode_block = true
      protection = true
    }

    content_type_options {
      override = true
    }

    referrer_policy {
      override        = true
      referrer_policy = "same-origin"
    }

    frame_options {
      override     = true
      frame_option = "DENY"
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
