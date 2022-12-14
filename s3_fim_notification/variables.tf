variable "bucket_name" {
  type = string
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