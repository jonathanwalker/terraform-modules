variable "role_name" {
  type        = string
  description = "The name of the role to create"
}

variable "role_description" {
  type        = string
  description = "The description of the role to create"
}

variable "policy_arns" {
  type        = list(string)
  description = "A list of policy ARNs to attach to the role"
}

variable "oidc_provider_arn" {
  type        = string
  description = "The ARN of the OIDC provider provided as an output from the iam_oidc_connector module"
}

variable "github_repository_name" {
  type        = string
  description = "The name of the GitHub repository"
}

variable "github_repository_org" {
  type        = string
  description = "The name of the GitHub organization"
}

variable "tags" {
  type = map(any)
  default = {
    "Name"  = "github-actions-role"
    "Owner" = "johnny"
  }
}