resource "aws_route53_zone" "zone" {
  name    = var.domain_name
  comment = var.zone_comment

  # Dynamic block to check if you want to create a private zone or not
  dynamic "vpc" {
    for_each = var.vpc_id == null ? [] : [var.vpc_id]
    content {
      vpc_id = vpc.value
    }
  }

  tags = var.tags
}