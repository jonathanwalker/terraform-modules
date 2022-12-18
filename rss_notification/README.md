# RSS Notification

Send an SNS notification for new RSS feed item by checking the RSS feed on a cron expression, dynamodb table for checking if alert has already been triggered, hours since to ensure recent notifications, and a filter that allows you to specify a string to filter the RSS feed.

### Bulletins

Below are a few examples as to which bulletins you can subscribe to.

- [Amazon Web Services Security Bulletin](https://aws.amazon.com/security/security-bulletins/rss/feed/) 
- [Jenkins Security Advisory](https://www.jenkins.io/security/advisories/rss.xml)
- [Grafana Security Advisory](https://grafana.com/tags/security/index.xml)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_log_group.log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_dynamodb_table.table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_policy.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic.topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [null_resource.build](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_name"></a> [alert\_name](#input\_alert\_name) | n/a | `string` | n/a | yes |
| <a name="input_cron_expression"></a> [cron\_expression](#input\_cron\_expression) | n/a | `string` | `"0 * * * ? *"` | no |
| <a name="input_hours_since"></a> [hours\_since](#input\_hours\_since) | The number of hours since the last RSS feed update | `number` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | n/a | `number` | `30` | no |
| <a name="input_rss_feed_url"></a> [rss\_feed\_url](#input\_rss\_feed\_url) | RSS Feed URL | `string` | n/a | yes |
| <a name="input_rss_filter"></a> [rss\_filter](#input\_rss\_filter) | Delimited list of strings by comma to filter RSS feed | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | <pre>{<br>  "Name": "s3-fim-notification",<br>  "Owner": "johnny"<br>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->