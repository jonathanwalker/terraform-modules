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

resource "null_resource" "build" {
  # trigger when src/main.go changes
  triggers = {
    main = filemd5("${path.module}/src/main.go")
  }
  
  provisioner "local-exec" {
    command = "cd ${path.module}/src && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o main"
  }
}

# permission to invoke lambda from bucket notification
resource "aws_lambda_permission" "s3_bucket_notification" {
  depends_on = [aws_s3_bucket_notification.s3_bucket_notification]

  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket_name}"
}