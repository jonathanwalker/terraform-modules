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

  response_headers {
    header_name  = "Strict-Transport-Security"
    header_value = "max-age=31536000"
  }

  headers {
    name  = "Content-Security-Policy"
    value = "default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; object-src 'none'; frame-ancestors 'none'"
  }

  response_headers {
    header_name  = "X-Content-Type-Options"
    header_value = "nosniff"
  }

  response_headers {
    header_name  = "X-Frame-Options"
    header_value = "DENY"
  }

  response_headers {
    header_name  = "X-XSS-Protection"
    header_value = "1; mode=block"
  }

  response_headers {
    header_name  = "Referrer-Policy"
    header_value = "same-origin"
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