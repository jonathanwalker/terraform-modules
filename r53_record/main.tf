resource "aws_route53_record" "record" {
  for_each = toset(var.record_map)

  zone_id = each.value.zone_id
  name    = each.value.name
  type    = each.value.type
  records = each.value.records

  ttl = var.record_ttl
}