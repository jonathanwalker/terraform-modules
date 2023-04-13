resource "unifi_network" "vlan" {
  for_each = var.vlans

  site_id     = var.site_id
  name        = each.value.name
  network     = each.value.network
  purpose     = "corporate"
  subnet      = cidrsubnet(each.value.network, 0, 1)
  dhcp_server = each.value.dhcp

  vlan_enabled = true
  vlan_id      = each.value.vlan_id
  parent_id    = 1
}
