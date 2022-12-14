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
    resources = [aws_sqs_queue.queue.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:s3:::${var.bucket_name}"]
    }
  }
}

# sqs queue to trigger lambda function
resource "aws_lambda_event_source_mapping" "mapping" {
  depends_on = [aws_sqs_queue_policy.queue_policy]

  enabled          = true
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = aws_lambda_function.function.arn
  batch_size       = var.batch_size

  maximum_batching_window_in_seconds = var.batch_window
}