variable "bucket_name" {
    type = string
}

variable "table_name" {
    type = string
}

variable "kms_key_admins" {
    type = "list"
    default = [
        "user/johnny"
    ]
}

variable "kms_key_users" {
    type = "list(string)"
    default = [
        "user/johnny"
    ]
}

variable "tags" {
    type = "map"
    default = {
        "Name" = "terraform-state"
        "Owner" = "johnny"
    }
}