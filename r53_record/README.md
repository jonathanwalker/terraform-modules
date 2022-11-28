<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_record_map"></a> [record\_map](#input\_record\_map) | n/a | <pre>map(object({<br>    zone_id = string<br>    name    = string<br>    type    = string<br>    records = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_record_ttl"></a> [record\_ttl](#input\_record\_ttl) | The ttl of the records | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_route53_record"></a> [route53\_record](#output\_route53\_record) | n/a |
<!-- END_TF_DOCS -->