variable "unifi_url" {
  type    = string
  default = "https://unifi:8443"
}

variable "site_id" {
  type    = string
  default = "default"
}

variable "unifi_username" {
  type    = string
  default = "admin"
  sensitive = true
}

variable "unifi_password" {
  type    = string
  default = "admin"
  sensitive = true
}

variable "networks" {
  type = map(object({
    name    = string
    purpose = string
    subnet  = string
    vlan_id = number
    site    = string
  }))
}