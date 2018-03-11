resource "aws_iam_role" "pipeline_spike_step_fn_invoker" {
  name = "pipeline_spike_step_fn_invoker"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "pipeline_spike_step_fn_invoker" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*"
    ]

    actions = [
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:DescribeStream",
      "kinesis:ListStreams",
    ]

    resources = [
      "${aws_kinesis_stream.pipeline_spike_stream.arn}"
    ]

    actions = [
      "states:StartExecution",
    ]

    resources = [
      "${aws_sfn_state_machine.pipeline_spike_step_fn.id}"
    ]

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.pipeline_spike_orphan_bucket.arn}",
      "${aws_s3_bucket.pipeline_spike_orphan_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "pipeline_spike_step_fn_invoker" {
  name   = "pipeline_spike_step_fn_invoker"
  role   = "${aws_iam_role.pipeline_spike_step_fn_invoker.name}"
  policy = "${data.aws_iam_policy_document.pipeline_spike_step_fn_invoker.json}"
}

resource "aws_lambda_function" "pipeline_spike_step_fn_invoker" {
  filename         = "../artifacts/step_fn_invoker.zip"
  function_name    = "pipeline_spike_step_fn_invoker"
  role             = "${aws_iam_role.pipeline_spike_step_fn_invoker.arn}"
  handler          = "step_fn_invoker"
  source_code_hash = "${base64sha256(file("../artifacts/step_fn_invoker.zip"))}"
  runtime          = "go1.x"

  environment {
    variables = {
      STEP_FN_ARN = "${aws_sfn_state_machine.pipeline_spike_step_fn.id}"
      S3_BUCKET = "${aws_s3_bucket.pipeline_spike_orphan_bucket.id}"
      S3_REGION = "${aws_s3_bucket.pipeline_spike_orphan_bucket.region}"
      S3_PREFIX = "INVOKER_"
    }
  }
}

resource "aws_lambda_event_source_mapping" "pipeline_spike_step_fn_invoker_kinesis_subscription" {
  batch_size        = 1
  event_source_arn  = "${aws_kinesis_stream.pipeline_spike_stream.arn}"
  enabled           = true
  function_name     = "${aws_lambda_function.pipeline_spike_step_fn_invoker.function_name}"
  starting_position = "TRIM_HORIZON"
}
