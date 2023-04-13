terraform {
  required_providers {
    unifi = {
      source = "paultyng/unifi"
      version = "0.41.0"
    }
  }
}

provider "unifi" {
  username = var.unifi_username
  password = var.unifi_password
  url = var.unifi_url

  allow_insecure = true # no valid cert yet
}