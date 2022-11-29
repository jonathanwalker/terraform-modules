
resource "aws_iam_role" "role" {
  name        = var.role_name
  description = var.role_description

  assume_role_policy = data.aws_iam_policy_document.document.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  for_each = var.policy_arns

  role       = aws_iam_role.role.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "document" {
  statement {
    sid     = "AssumeRoleFromOIDCProvider"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository_org}/${var.github_repository_name}:*"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}