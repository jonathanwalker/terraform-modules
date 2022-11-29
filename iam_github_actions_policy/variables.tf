variable "policy_name" {
  type        = string
  description = "The name of the policy to create"
}

variable "policy_description" {
  type        = string
  description = "The description of the policy to create"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket to write to"
}

variable "tags" {
  type = map(any)
  default = {
    "Name"  = "github-actions-role"
    "Owner" = "johnny"
  }
}