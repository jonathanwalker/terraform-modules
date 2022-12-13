
###
# Bucket inventory configurations
###
resource "aws_s3_bucket_inventory" "inventory" {
  for_each = var.s3_inventory_configuration

  name   = "${each.value["bucket"]}-inventory"
  bucket = each.value["bucket"]

  included_object_versions = each.value["included_object_versions"]
  optional_fields          = each.value["optional_fields"]
  schedule {
    frequency = each.value["frequency"]
  }

  destination {
    bucket {
      bucket_arn = aws_s3_bucket.inventory_bucket.arn
      format = each.value["format"]
    }
  }
}

###
# Inventory Bucket
###
# tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "inventory_bucket" {
  bucket = var.report_bucket
  tags   = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "inventory_bucket" {
  bucket = aws_s3_bucket.inventory_bucket.id

  rule {
    id      = "inventory-expiration"
    status  = "Enabled"

    expiration {
      days = var.inventory_expiration_days
    }
  }
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "inventory_bucket" {
  bucket = aws_s3_bucket.inventory_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "inventory_bucket" {
  bucket = aws_s3_bucket.inventory_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "inventory_bucket_policy" {
  bucket = aws_s3_bucket.inventory_bucket.id
  policy = data.aws_iam_policy_document.inventory_bucket_policy.json
}

data "aws_iam_policy_document" "inventory_bucket_policy" {
  statement {
    sid    = "AllowInventoryReports"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.inventory_bucket.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = [for i in var.s3_inventory_configuration : "arn:aws:s3:::${i["bucket"]}"]
    }
  }
}

