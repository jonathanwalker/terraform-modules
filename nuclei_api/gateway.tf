# current region
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

resource "aws_route53_record" "record" {
  name = var.domain
  type = "A"
  zone_id = var.zone_id
  alias {
    name = aws_api_gateway_rest_api.gateway.execution_arn
    zone_id = aws_api_gateway_rest_api.gateway.regional_domain_name
    evaluate_target_health = false
  }
}
