variable "cluster_name" {
  description = "The name of the cluster"
  default     = "media-network"
}

variable "vpc_id" {
  description = "The VPC ID"
}

variable "vpc_cidr" {
  description = "The VPC CIDR"
}

variable "public_subnets" {
  description = "The public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "The private subnet CIDRs"
  type        = list(string)
}

variable "allowed_ips" {
  description = "The allowed IPs"
  type        = list(string)
}

variable "zone_id" {
  description = "The zone ID"
}

variable "dns_name" {
  description = "jellyfin.example.com"
}

variable "tags" {
  type = map(string)
  default = {
    "Name"  = "media-network"
    "Owner" = "johnny"
  }
}