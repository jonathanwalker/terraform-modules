# Terraform Modules

This repository contains all the terraform modules I need to setup my environment. 

- Static code analysis with `tfsec`
- Executed through [Terragrunt](https://terragrunt.gruntwork.io/)
- GitHub actions on pull request for static code analysis
- Opinionated modules for my own use

## Modules

Here are the current modules on the repository and what they do. 

- KMS key module to create a PoLP key
- S3 static site for Hugo/MKDocs site
- Remote state for my terraform
- Route53 zone and records
- GitHub OIDC authentication for IAM roles

## Documentation

Leveraging [Terraform Docs](https://github.com/terraform-docs/terraform-docs) to output the modules documentation.

```
terraform-docs markdown . --output-file README.md
```

## Format

Be sure to use `terraform fmt .` prior to submitting your pull request. 