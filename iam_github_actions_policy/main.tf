data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "policy" {
  name        = var.policy_name
  description = var.policy_description

  policy = data.aws_iam_policy_document.document.json
}

# Create a policy document for read-only access to the S3 bucket
data "aws_iam_policy_document" "document" {
  version = "2012-10-17"

  statement {
    sid = "WriteOnlyAccess"

    actions = [
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*",
    ]
  }

  statement {
    sid = "CloudFrontInvalidation"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    resources = [
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}"
    ]
  }
}
