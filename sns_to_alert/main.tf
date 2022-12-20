# lambda function golang
# tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "function" {
  filename      = "lambda.zip"
  function_name = "${var.alert_name}-function"

  role           = aws_iam_role.lambda_role.arn

  handler     = "main"
  runtime     = "go1.x"
  timeout     = 300
  memory_size = 128

  source_code_hash = data.archive_file.zip.output_base64sha256

  environment {
    variables = {
      SLACK_WEBHOOK    = var.slack_webhook_url
    }
  }

  tags = var.tags
}

resource "aws_sns_topic_subscription" "subscription" {
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.function.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.arn
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}

data "archive_file" "zip" {
  depends_on  = [null_resource.build]
  type        = "zip"
  source_file = "src/main"
  output_path = "lambda.zip"
}

# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/aws/lambda/${var.alert_name}-function"

  retention_in_days = var.log_retention_days

  tags = var.tags
}
