data "archive_file" "archive" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda" {
  count = var.enable_lambda_edge_function ? 1 : 0

  function_name = replace(var.domain_name, ".", "-")

  filename         = data.archive_file.archive.output_path
  role             = aws_iam_role.lambda[0].arn
  source_code_hash = data.archive_file.archive.output_base64sha256

  handler      = "index.handler"
  runtime      = "nodejs12.x"
  timeout      = 300
  memory_size  = 128
  publish      = true
}

resource "aws_iam_role" "lambda" {
  # conditional resource based on variable is true or false
  count = var.enable_lambda_edge_function ? 1 : 0

  name        = "${replace(var.domain_name, ".", "-")}-lambda-edge"
  description = "Lambda@Edge function for ${var.domain_name}"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}