# aws iam open id connect provider github
resource "aws_iam_openid_connect_provider" "provider" {
  url             = var.openid_url
  client_id_list  = var.client_id_list
  thumbprint_list = var.thumbprint_list

  tags = var.tags
}