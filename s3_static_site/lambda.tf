data "archive_file" "archive" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda" {
  # conditional resource based on variable is true or false
  count = var.enable_lambda_edge_function ? 1 : 0

  function_name = "${replace(var.domain_name, ".", "-")}-lambda-edge"

  filename         = data.archive_file.archive.output_path
  role             = aws_iam_role.lambda[count.index].arn
  source_code_hash = data.archive_file.archive.output_base64sha256

  handler     = "index.handler"
  runtime     = "nodejs12.x"
  timeout     = 10
  memory_size = 128
  publish     = true
}

resource "aws_iam_role" "lambda" {
  # conditional resource based on variable is true or false
  count = var.enable_lambda_edge_function ? 1 : 0

  name        = "${replace(var.domain_name, ".", "-")}-lambda-edge"
  description = "Lambda@Edge function for ${var.domain_name}"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  # conditional resource based on variable is true or false
  count = var.enable_lambda_edge_function ? 1 : 0

  role       = aws_iam_role.lambda[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
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