output "bucket" {
  value = aws_s3_bucket.s3_bucket.id
}

output "dynamodb" {
  value = aws_dynamodb_table.dynamodb_table.id
}

output "kms_key_arn" {
  value = aws_kms_key.kms_key.arn
}