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

variable "enable_lambda_edge_function" {
  type    = bool
  default = false
}

variable "enable_security_headers" {
  type    = bool
  default = true
}

variable "content_security_policy" {
  type    = string
  default = "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self';"
}

variable "access_control_max_age_sec" {
  type    = number
  default = 31536000
}

variable "tags" {
  type = map(string)
  default = {
    "Name"  = "example.com"
    "Owner" = "johnny"
  }
}