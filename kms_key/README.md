# KMS Key

Module for creating a KMS key with a list of administrators and users. The administrators do not have access to encrypt/decrypt, users only have the ability to encrypt/decrypt, and supports multiple IAM entities(users, roles, and groups). 

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
| [aws_kms_alias.kms_key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deletion_window"></a> [deletion\_window](#input\_deletion\_window) | The number of days to wait before deleting the key | `number` | `14` | no |
| <a name="input_kms_alias"></a> [kms\_alias](#input\_kms\_alias) | KMS alias name for the key which should be like alias/alias-name | `string` | n/a | yes |
| <a name="input_kms_description"></a> [kms\_description](#input\_kms\_description) | KMS key description | `string` | n/a | yes |
| <a name="input_kms_key_admins"></a> [kms\_key\_admins](#input\_kms\_key\_admins) | List of users who should have admin access to the KMS key(role/role-name, user/user-name, group/group-name) | `list(string)` | <pre>[<br>  "user/johnny"<br>]</pre> | no |
| <a name="input_kms_key_users"></a> [kms\_key\_users](#input\_kms\_key\_users) | List of users who should have decrypt/encrypt access to the KMS key(role/role-name, user/user-name, group/group-name) | `list(string)` | <pre>[<br>  "user/johnny"<br>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to be applied to the KMS key | `map` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | n/a |
<!-- END_TF_DOCS -->