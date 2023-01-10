

# Attach the necessary permissions policy to the IAM role
resource "aws_iam_policy" "grafana_policy" {
  name = "grafana_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "athena:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::aws-athena-query-results-*",
        "arn:aws:s3:::aws-athena-query-results-*/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "grafana_attachment" {
  name = "grafana_attachment"
  roles = [aws_iam_role.grafana_role.name]
  policy_arn = aws_iam_policy.grafana_policy.arn
}

# Create the Grafana instance
resource "aws_grafana_instance" "grafana" {
  name = "grafana"
  iam_role_arn = aws_iam_role.grafana_role.arn
}

# Create an Athena data source
resource "aws_grafana_datasource" "athena" {
  name = "athena"
  type = "athena"
  url = "https://athena.${aws_grafana_instance.grafana.region}.amazonaws.com"
  access_mode = "direct"
  database_name = "default"
  is_default = true
  grafana_instance_id = aws_grafana_instance.grafana.id
}






###
# IAM
###
resource "aws_iam_role" "role" {
  name = "grafana-role"

  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = var.tags
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }
  }
}

# attach policy to role
resource "aws_iam_role_policy_attachment" "policy" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

# IAM policy for lambda
resource "aws_iam_policy" "policy" {
  name        = "grafana-policy"
  description = "Policy for grafana instance"

  policy = data.aws_iam_policy_document.policy.json
}

# tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "policy" {
  statement {
    sid = "AthenaS3Access"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      for bucket in var.s3_buckets : "arn:aws:s3:::${bucket}",
      for bucket in var.s3_buckets : "arn:aws:s3:::${bucket}/*"
    ]
  }

  statement {
    sid = "QueryResults"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::aws-athena-query-results-*",
      "arn:aws:s3:::aws-athena-query-results-*/*"
    ]
  }

  statement {
    sid    = "Athena"
    effect = "Allow"
    actions = [
      "athena:*"
    ]
    resources = [
      "*"
    ]
  }
}