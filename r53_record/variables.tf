variable "record_map" {
  type = map(object({
    zone_id = string
    name    = string
    type    = string
    records = list(string)
  }))
}

variable "record_ttl" {
  type        = number
  default     = 300
  description = "The ttl of the records"
}