variable "report_bucket" {
  type = string
}

variable "max_bytes_scanned_per_query" {
  type = number
  default = 100000000000 # 100 GB
}

variable "results_expiration_dayes" {
  type = number
  default = 90
}

variable "tags" {
  type = map(string)
}