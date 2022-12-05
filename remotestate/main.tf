#tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "s3_bucket" {
    bucket = var.bucket_name
    lifecycle {
        prevent_destroy = true
    }

    tags = var.tags
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
    bucket = aws_s3_bucket.s3_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_sse" {
    bucket = aws_s3_bucket.s3_bucket.id
    rule {
        apply_server_side_encryption_by_default {
            kms_master_key_id = aws_kms_key.kms_key.arn
            sse_algorithm     = "aws:kms"
        }
    }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
    bucket = aws_s3_bucket.s3_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

# DynamoDB table for storing state locks
resource "aws_dynamodb_table" "dynamodb_table" {
    name           = var.table_name
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "LockID"
    read_capacity  = 0
    write_capacity = 0

    # kms encryption
    server_side_encryption {
        enabled     = true
        kms_key_arn = aws_kms_key.kms_key.arn
    }

    # You never know
    point_in_time_recovery {
        enabled = true
    }

    attribute {
        name = "LockID"
        type = "S"
    }

    lifecycle {
        prevent_destroy = true
    }

    tags = var.tags
}