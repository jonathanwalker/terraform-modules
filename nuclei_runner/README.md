# Nuclei Runner

![Infrastructure](/static/infrastructure.png)

This terraform module allows you to execute [Nuclei](https://github.com/projectdiscovery/nuclei) within a [lambda function](https://aws.amazon.com/lambda/) within AWS. This is designed to be the backend for [Nuclear Pond](https://github.com/DevSecOpsDocs/Nuclear-Pond). Please go to that repository first if you have not. The purpose of which is to allow you to perform automated scans on your infrastructure and allow the results to be parsed in any way that you choose. 

Nuclei can help you identify technologies running within your infrastructure, misconfigurations, exploitable vulnerabilities, network protocols, default credentials, exposed panels, takeovers, and so much more. Continuously monitoring for such vulnerabilities within your network can be crucial to providing you with a last line of defense against vulnerabilities hidden within your cloud infrastructure. 

> :warning: **This is vulnerable to Remote Code Execution**: Be careful where you deploy this as I have made no attempt to sanitize inputs for flexibility purposes. Since it is running in lambda, the risk is generally low but if you were to attach a network interface to this it could add significant risk. 

## Engineering Decisions

With any engineering project, design decisions are made based on the requirements of a given project. In which these designs have some limitations which are the following:

- Args are passed directly, to allow you to specify any arguments to nuclei, in invoking the lambda function and since the sink is `exec.Command` this is vulnerable to remote code execution by design and can be easily escaped
- Never pass `-u`, `-l`, `-json`, or `-o` flag to this lambda function but you can pass any other nuclei arguments you like
- Nuclei refuses to not write to `$HOME/.config` so the `HOME`, which is not a writable filesystem with lambda, is set to `/tmp` which can cause warm starts to have the same filesystem and perhaps poison future configurations
- Lambda function in golang is rebuilt on every apply for ease of development

### Event Json

This is what must be passed to the lambda function. The `Targets` can be a list of one or many, the lambda function will handle passing in the `-u` or `-l` flag accordingly. The `Args` input are any valid flags for nuclei. The `Output` flag allows you to output either the command line output, json findings, or s3 key where the results are uploaded to. 

```
{
  "Targets": [
    "https://devsecopsdocs.com"
  ],
  "Args": [
    "-t",
    "dns"
  ],
  "Output": "json"
}
```

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
| [aws_cloudwatch_log_group.log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_alias.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_alias) | resource |
| [aws_lambda_function.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_layer_version.layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_object.upload_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.upload_nuclei](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [null_resource.build](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.download-nuclei](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.report_config](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | n/a | `number` | `512` | no |
| <a name="input_nuclei_arch"></a> [nuclei\_arch](#input\_nuclei\_arch) | Nuclei architecture to use | `string` | `"linux_amd64"` | no |
| <a name="input_nuclei_args"></a> [nuclei\_args](#input\_nuclei\_args) | n/a | `list(string)` | <pre>[<br>  "-u",<br>  "https://devsecopsdocs.com",<br>  "-ud",<br>  "/tmp/",<br>  "-rc",<br>  "/opt/report-config.yaml",<br>  "-t",<br>  "technologies/aws",<br>  "-stats",<br>  "-c",<br>  "50",<br>  "-rl",<br>  "300",<br>  "-timeout",<br>  "5"<br>]</pre> | no |
| <a name="input_nuclei_timeout"></a> [nuclei\_timeout](#input\_nuclei\_timeout) | n/a | `number` | `900` | no |
| <a name="input_nuclei_version"></a> [nuclei\_version](#input\_nuclei\_version) | Nuclei version to use | `string` | `"2.8.3"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | `"nuclei-scanner"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | <pre>{<br>  "Name": "nuclei-scanner",<br>  "Owner": "johnny"<br>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->