# tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "function" {
  filename      = "lambda.zip"
  function_name = "${var.project_name}-function"

  role   = aws_iam_role.lambda_role.arn
  # layers = [aws_lambda_layer_version.layer.arn]

  handler     = "main"
  runtime     = "go1.x"
  timeout     = var.timeout
  memory_size = var.memory_size

  source_code_hash = data.archive_file.zip.output_base64sha256

  environment {
    variables = {
      AWS_LAMBDA_FUNCTION_CONNECTION_REUSE_ENABLED = "false"
    }
  }

  # environment {
  #   variables = {
  #     "BUCKET_NAME" = aws_s3_bucket.bucket.id
  #   }
  # }

  tags = var.tags
}

resource "aws_lambda_alias" "alias" {
  name             = var.project_name
  description      = "Nuclei scanner lambda function"
  function_name    = aws_lambda_function.function.arn
  function_version = "$LATEST"
}

# lambda permission to invoke from api gateway
resource "aws_lambda_permission" "permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = aws_api_gateway_deployment.deployment.execution_arn
}

# Layer to run nuclei in lambda
# resource "aws_lambda_layer_version" "layer" {
#   depends_on          = [aws_s3_object.upload_nuclei]
#   layer_name          = "${var.project_name}-layer"
#   s3_bucket           = aws_s3_bucket.bucket.id
#   s3_key              = "nuclei.zip"
#   compatible_runtimes = ["go1.x"]
# }

# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/aws/lambda/${var.project_name}-function"

  retention_in_days = 90

  tags = var.tags
}

###
# IAM
###
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-role"

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
  name        = "${var.project_name}-policy"
  description = "Policy for lambda"

  policy = data.aws_iam_policy_document.policy.json
}

# tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "policy" {
  statement {
    sid = "AllowCloudWatchLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  # statement {
  #   sid    = "AllowS3Upload"
  #   effect = "Allow"
  #   actions = [
  #     "s3:PutObject"
  #   ]
  #   resources = [
  #     "arn:aws:s3:::${aws_s3_bucket.bucket.id}/findings/*"
  #   ]
  # }
}