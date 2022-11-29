variable "openid_url" {
  type    = string
  default = "https://token.actions.githubusercontent.com"
}

variable "client_id_list" {
  type = list(string)
  default = [
    "https://github.com/jonathanwalker"
  ]
}

variable "thumbprint_list" {
  type = list(string)
  default = [
    "6938fd4d98bab03faadb97b34396831e3780aea1" # github.com
  ]
}

variable "tags" {
  type = map(any)
  default = {
    "Name"  = "github-oidc-connector"
    "Owner" = "johnny"
  }
}