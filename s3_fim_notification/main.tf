# s3_bucket_notification to lambda function
resource "aws_s3_bucket_notification" "s3_bucket_notification" {
  depends_on = [aws_lambda_function.function]
  
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.function.arn
    events              = var.s3_events
    filter_prefix       = var.filter_prefix
    filter_suffix       = var.filter_suffix
  }
}
