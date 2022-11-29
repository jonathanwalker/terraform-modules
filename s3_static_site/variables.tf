variable "domain_name" {
  type    = string
  default = "example.com"
}

variable "zone_id" {
  type    = string
  default = "Z1234567890"
}

variable "default_root_object" {
  type    = string
  default = "index.html"
}

variable "bucket_name" {
  type    = string
  default = "example.com"
}

variable "tags" {
  type    = map(string)
  default = {
    "Name" = "example.com"
    "Owner" = "johnny"
  }
}