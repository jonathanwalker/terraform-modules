variable "policy_name" {
  type        = string
  description = "The name of the role to create"
}

variable "policy_arns" {
  type        = list(string)
  description = "A list of policy ARNs to attach to the role"
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