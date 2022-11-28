variable "domain_name" {
  type = string
  default = "example.com"
}

variable "zone_comment" {
  type = string
  default = "Managed by Terraform"
}

# vpc_id variable dynamic block default null
variable "vpc_id" {
  type = string
  default = null
}

variable "tags" {
    type = map
    default = {
        "Name" = "example.com"
        "Owner" = "johnny"
    }
}