variable "alert_name" {
  type = string
}

variable "rss_feed_url" {
  type        = string
  description = "RSS Feed URL"
}

variable "hours_since" {
  type        = number
  description = "The number of hours since the last RSS feed update"
}

variable "rss_filter" {
  type        = string
  description = "Delimited list of strings by comma to filter RSS feed"
}

variable "cron_expression" {
  type    = string
  default = "0 * * * ? *"
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