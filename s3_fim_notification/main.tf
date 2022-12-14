resource "aws_s3_bucket_notification" "s3_bucket_notification" {
  bucket = var.bucket_name

  topic {
    topic_arn = aws_sns_topic.sns_topic.arn
    events    = var.s3_events
  }
}
