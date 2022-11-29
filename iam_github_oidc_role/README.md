# GitHub OIDC Role

This module allows you to leverage [OpenID Connect](https://openid.net/connect/) with AWS and GitHub to allow for keyless access to GitHub actions runners. Leveraging the `iam_oidc_connector`, `iam_github_actions_policy`, and this module you can create the ability to leverage github actions to write data to S3. This is great for static sites in which you wish to build and push to S3. 

[https://github.com/aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)

# Static Site Build Example

This example goes over how to deploy an mkdocs site leveraging github actions. Using the `s3_static_site` module you can create your infrastructure and leverage these modules to deploy your static site on push. 

```
name: Deploy static site
on:
  push:
    branches:
      - main
env:
  BUCKET_NAME: "example-static-site"
  ROLE_ARN:    "arn:aws:iam::111111111111:role/my-github-actions-role-test"
  AWS_REGION:  "us-east-1"
jobs:
  deploy:
    runs-on: ubuntu-latest
    if: github.event.repository.fork == false
    steps:
      - uses: actions/setup-python@v2
        with:
          python-version: 3.x
      - run: pip install mkdocs
      - run: pip install mkdocs-material 
      - name: Checkout Repository
        uses: actions/checkout@v3
      - run: mkdocs build
      - name: Configure AWS credentials from Test account
        uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: ${{ env.ROLE_NAME }}
          aws-region: ${{ env.AWS_REGION }}
      - name: Sync static site
        run: |
          cd site/
          aws s3 sync . s3://${{ env.BUCKET_NAME }}/
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_github_repository_name"></a> [github\_repository\_name](#input\_github\_repository\_name) | The name of the GitHub repository | `string` | n/a | yes |
| <a name="input_github_repository_org"></a> [github\_repository\_org](#input\_github\_repository\_org) | The name of the GitHub organization | `string` | n/a | yes |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | The ARN of the OIDC provider provided as an output from the iam\_oidc\_connector module | `string` | n/a | yes |
| <a name="input_policy_arns"></a> [policy\_arns](#input\_policy\_arns) | A list of policy ARNs to attach to the role | `list(string)` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | The name of the role to create | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | <pre>{<br>  "Name": "github-actions-role",<br>  "Owner": "johnny"<br>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->