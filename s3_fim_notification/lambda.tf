# lambda function golang
resource "aws_lambda_function" "function" {
  filename      = "lambda.zip"
  function_name = "lambda_function"

  role           = aws_iam_role.lambda_role.arn
  log_group_name = aws_cloudwatch_log_group.log_group.name

  handler     = "Handler"
  runtime     = "go1.x"
  timeout     = 300
  memory_size = 128

  source_code_hash = data.archive_file.zip.output_base64sha256

  tags = var.tags
}

data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "src/"
  output_path = "lambda.zip"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "lambda_log_group"

  retention_in_days = var.log_retention_days

  tags = var.tags
}

###
# IAM
###
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = data.aws_iam_policy_document.policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}