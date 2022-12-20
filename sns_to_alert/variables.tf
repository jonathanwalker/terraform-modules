variable "alert_name" {
  type = string
}

variable "sns_topic_arn" {
  type        = string
}

variable "log_retention_days" {
  type = number
  default = 30
}

variable "tags" {
  type = map(string)
  default = {
    "Name"  = "sns-notification"
    "Owner" = "johnny"
  }
}