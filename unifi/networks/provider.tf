provider "unifi" {
  username = "${env.UNIFI_USERNAME}"
  password = "${env.UNIFI_PASSWORD}"
  url = var.unifi_url
}