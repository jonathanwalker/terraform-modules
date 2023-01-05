data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "gateway" {
  name = "${var.project_name}-gateway"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  parent_id = aws_api_gateway_rest_api.gateway.root_resource_id
  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method

  type = "AWS_PROXY"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.function.arn}/invocations"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  stage_name = "prod"

  depends_on = [aws_api_gateway_integration.integration]
}

resource "aws_api_gateway_domain_name" "domain" {
  domain_name              = var.domain
  regional_certificate_arn = aws_acm_certificate_validation.validation.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_acm_certificate" "certificate" {
  domain_name       = var.domain
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

resource "aws_acm_certificate_validation" "validation" {
  depends_on = [aws_route53_record.record_validation]
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.record_validation : record.fqdn]
}

resource "aws_route53_record" "record" {
  name = var.domain
  type = "A"
  zone_id = var.zone_id
  alias {
    name = aws_api_gateway_domain_name.domain.regional_domain_name
    zone_id = aws_api_gateway_domain_name.domain.regional_zone_id
    evaluate_target_health = false
  }
}