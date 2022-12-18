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
      RSS_FEED_URL    = var.rss_feed_url
      HOURS_SINCE     = var.hours_since
      RSS_FILTER      = var.rss_filter
      DYNAMODB_TABLE  = aws_dynamodb_table.table.name
      ALERT_TOPIC     = aws_sns_topic.topic.arn
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "trigger" {
  name        = "${var.alert_name}-trigger"
  description = "Trigger lambda function for ${var.alert_name} at ${var.cron_expression}"
  schedule_expression = "cron(${var.cron_expression})"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger.arn
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

###
# IAM
###
resource "aws_iam_role" "lambda_role" {
  name = "${var.alert_name}-role"

  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = var.tags
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# attach policy to role
resource "aws_iam_role_policy_attachment" "policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.policy.arn
}

# IAM policy for lambda
resource "aws_iam_policy" "policy" {
  name        = "${var.alert_name}-policy"
  description = "Policy for lambda"

  policy = data.aws_iam_policy_document.policy.json
}

# tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "policy" {
  statement {
    sid     = "AllowDynamoDBGetPut"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem"
    ]

    resources = [aws_dynamodb_table.table.arn]
  }
    statement {
    sid     = "AllowSNSNotification"
    actions = [
      "sns:Publish"
    ]

    resources = [aws_sns_topic.topic.arn]
  }
  statement {
    sid     = "AllowCloudWatchLogs"
    actions = [
      "logs:CreateLogGroup", 
      "logs:CreateLogStream", 
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}