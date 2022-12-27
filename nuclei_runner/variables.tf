variable "nuclei_version" {
  description = "Nuclei version to use"
  default     = "2.8.3"
}

variable "nuclei_arch" {
  description = "Nuclei architecture to use"
  default     = "linux_amd64"
}

variable "project_name" {
  description = "Name of the project"
  default     = "nuclei-scanner"
}

variable "nuclei_args" {
  type    = list(string)
  default = ["-u", "https://devsecopsdocs.com", "-ud", "/tmp/nuclei-templates", "-t", "takeovers/", "-stats", "-c", "50", "-rl", "300", "-timeout", "5""]
}

variable "tags" {
  type = map(string)
  default = {
    "Name"  = "nuclei-scanner"
    "Owner" = "johnny"
  }
}