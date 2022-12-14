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

# Build the lambda function which is rebuilt on change
resource "null_resource" "lambda_build" {
  triggers = {
    main = filesha256("src/main.go")
  }

  provisioner "local-exec" {
    command = "export GO111MODULE=on"
  }

  provisioner "local-exec" {
    command = "GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ${path.module}/src/bin/main ${path.module}/src/"
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