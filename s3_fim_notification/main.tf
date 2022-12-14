# s3_bucket_notification to lambda function
resource "aws_s3_bucket_notification" "s3_bucket_notification" {
  depends_on = [aws_lambda_function.function]

  bucket = var.bucket_name

  queue {
    queue_arn = aws_sqs_queue.queue.arn
    events    = var.s3_events

    filter_prefix = var.filter_prefix
    filter_suffix = var.suffix_filter
  }
}

# create sqs queue for s3_bucket_notification
resource "aws_sqs_queue" "queue" {
  name = "${var.bucket_name}-fim-queue"
}

# create sqs queue policy for s3_bucket_notification
resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id

  policy = data.aws_iam_policy_document.queue_policy.json
}

data "aws_iam_policy_document" "queue_policy" {
  statement {
    sid = "sqs_policy"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = ["SQS:SendMessage"]
    resources = [aws_sqs_queue.sqs_queue.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [aws_s3_bucket_notification.s3_bucket_notification.arn]
    }
  }
}

# sqs queue to trigger lambda function
resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  depends_on = [aws_sqs_queue_policy.queue_policy]

  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = aws_lambda_function.function.arn
  batch_size       = var.batch_size
  enabled          = true
}