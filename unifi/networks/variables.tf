variable "unifi_url" {
  type    = string
  default = "https://unifi:8443"
}

variable "site_id" {
  type    = string
  default = "default"
}

variable "vlans" {
  type = map(object({
    name     = string
    vlan_id  = number
    network  = string
    dhcp     = bool
  }))
}
