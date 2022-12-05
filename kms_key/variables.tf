variable "kms_alias" {
  type        = string
  description = "KMS alias name for the key which should be like alias/alias-name"
}

variable "kms_description" {
  type        = string
  description = "KMS key description"
}

variable "tags" {
  type        = map(any)
  description = "Map of tags to be applied to the KMS key"
}

variable "deletion_window" {
  type        = number
  default     = 14
  description = "The number of days to wait before deleting the key"
}

variable "kms_key_admins" {
  type = list(string)
  default = [
    "user/johnny"
  ]
  description = "List of users who should have admin access to the KMS key(role/role-name, user/user-name, group/group-name)"
}

variable "kms_key_users" {
  type = list(string)
  default = [
    "user/johnny"
  ]
  description = "List of users who should have decrypt/encrypt access to the KMS key(role/role-name, user/user-name, group/group-name)"
}
