terraform {
  required_providers {
    unifi = {
      source = "paultyng/unifi"
      version = "0.41.0"
    }
  }
}

provider "unifi" {
  username = "${env.UNIFI_USERNAME}"
  password = "${env.UNIFI_PASSWORD}"
  url = var.unifi_url

  allow_insecure = true # no valid cert yet
}