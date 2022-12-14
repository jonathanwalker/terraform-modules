# s3_bucket_notification to lambda function
resource "aws_s3_bucket_notification" "notification" {
  depends_on = [aws_lambda_function.function]

  bucket = var.bucket_name

  queue {
    queue_arn = aws_sqs_queue.queue.arn
    events    = var.s3_events

    filter_prefix = var.filter_prefix
    filter_suffix = var.filter_suffix
  }
}
