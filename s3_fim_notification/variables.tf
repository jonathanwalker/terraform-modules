variable "bucket_name" {
  type = string
}

variable "batch_size" {
  type = number
  default = 5000
  description = "The number of files to process in each batch to reduce alerts"
}

variable "batch_window" {
  type = number
  default = 60
  description = "The number of seconds to wait before the lambda function executes"
}

variable "lambda_timeout" {
  type = number
  default = 300
  description = "The number of seconds to wait before the lambda function times out"
}

variable "filter_prefix" {
  type = string
  default = ""
}

variable "filter_suffix" {
  type = string
  default = ""
}

variable "s3_events" {
  type = list(string)
  default = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
}

variable "log_retention_days" {
  type = number
  default = 30
}

variable "tags" {
  type = map(string)
  default = {
    "Name"  = "s3-fim-notification"
    "Owner" = "johnny"
  }
}