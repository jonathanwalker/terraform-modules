output "hosted_zone_id" {
  value = aws_route53_zone.zone.zone_id
}

output "hosted_zone_name" {
  value = aws_route53_zone.zone.name
}