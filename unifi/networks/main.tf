resource "unifi_network" "vlan" {
  for_each = var.networks

  site_id    = "your_site_id"
  name       = each.value.name
  purpose    = each.value.purpose
  subnet     = each.value.subnet
  ip_forward = true

  gateway {
    ip = each.value.gateway_ip
  }

  dhcpd {
    enabled         = true
    start           = each.value.dhcp_start
    stop            = each.value.dhcp_stop
    domain_name     = "your_network_domain_name"
    lease_time      = "your_network_lease_time"
    ntp_server      = "your_network_ntp_server"
    wins_server     = "your_network_wins_server"
    excluded_ranges = ["your_network_excluded_range_1", "your_network_excluded_range_2"]
  }
}
