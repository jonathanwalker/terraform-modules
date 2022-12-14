# s3_bucket_notification to lambda function
resource "aws_s3_bucket_notification" "s3_bucket_notification" {
  bucket = aws_s3_bucket.s3_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.function.arn
    events              = var.s3_events
    filter_prefix       = var.filter_prefix
    filter_suffix       = var.filter_suffix
  }
}


resource "aws_s3_bucket_notification" "s3_bucket_notification" {
  bucket = var.bucket_name

  topic {
    topic_arn = aws_sns_topic.sns_topic.arn
    events    = var.s3_events
  }
}
