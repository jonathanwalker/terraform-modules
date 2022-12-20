data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "bucket" {
  bucket = "aws-athena-query-results-${data.aws_caller_identity.current.id}-${data.aws_region.current.name}"
  tags   = var.tags
}

# tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.bucket.bucket

  rule {
    id     = "expire"
    status = "Enabled"

    expiration {
      days = var.results_expiration_dayes
    }
  }
}

resource "aws_s3_bucket_public_access_block" "blocks" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# tfsec:ignore:aws-athena-enable-at-rest-encryption
resource "aws_athena_workgroup" "workgroup" {
  name = "primary"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    bytes_scanned_cutoff_per_query = var.max_bytes_scanned_per_query

    result_configuration {
      output_location = "s3://${aws_s3_bucket.bucket.id}/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = var.tags
}
