# tfsec:ignore:aws-dynamodb-table-customer-key tfsec:ignore:aws-dynamodb-enable-recovery tfsec:ignore:aws-dynamodb-enable-at-rest-encryption
resource "aws_dynamodb_table" "table" {
  name           = "${var.alert_name}-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "url"
  attribute {
    name = "url"
    type = "S"
  }

  tags = var.tags
}

# tfsec:ignore:aws-sns-enable-topic-encryption
resource "aws_sns_topic" "topic" {
  name = "${var.alert_name}-topic"
  
  tags = var.tags
}