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
    sid     = "AllowCloudWatchLogs"
    actions = [
      "logs:CreateLogGroup", 
      "logs:CreateLogStream", 
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}