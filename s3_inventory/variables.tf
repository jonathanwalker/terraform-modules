variable "report_bucket" {
  type = string
}

variable "s3_inventory_configuration" {
  type = list(object({
    bucket                   = string
    included_object_versions = string
    optional_fields          = list(string)
    frequency                = string
    destination_bucket       = string
    format                   = string
    prefix                   = string
  }))
}

variable "tags" {
  type = map(string)
}

variable "inventory_expiration_days" {
  type    = number
  default = 30
}