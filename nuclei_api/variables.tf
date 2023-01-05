# variable "nuclei_version" {
#   description = "Nuclei version to use"
#   default     = "2.8.3"
# }

# variable "nuclei_arch" {
#   description = "Nuclei architecture to use"
#   default     = "linux_amd64"
# }

variable "domain" {
  default = "api.devsecopsdocs.com"
}

variable "zone_id" {
  default = "Z3E2SVHCIAIP7Z"
}

variable "project_name" {
  description = "Name of the project"
  default     = "nuclei-scanner"
}

variable "timeout" {
  type    = number
  default = 900
}

variable "memory_size" {
  type    = number
  default = 512
}

variable "tags" {
  type = map(string)
  default = {
    "Name"  = "nuclei-scanner"
  }
}