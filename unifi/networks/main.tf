resource "unifi_network" "networks" {
  for_each = var.networks

  name    = each.value.name
  purpose = each.value.purpose
  subnet  = each.value.subnet
  vlan_id = each.value.vlan_id
  site    = each.value.site

  dhcp_enabled = true
  dhcp_start   = each.value.dhcp_start
  dhcp_stop    = each.value.dhcp_stop
  dhcp_lease   = 86400

  ipv6_ra_enable            = true
  ipv6_ra_priority          = "medium"
  ipv6_ra_preferred_lifetime = 14400
  ipv6_ra_valid_lifetime     = 86400
}
