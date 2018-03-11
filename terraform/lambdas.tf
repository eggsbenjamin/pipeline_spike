resource "aws_iam_role" "pipeline_spike_lambda" {
  name = "pipeline_spike_lambda"

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

data "aws_iam_policy_document" "pipeline_spike_lambda" {
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
      "kinesis:PutRecord",
    ]

    resources = [
      "${aws_kinesis_stream.pipeline_spike_stream.arn}"
    ]

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.pipeline_spike_valid_bucket.arn}",
      "${aws_s3_bucket.pipeline_spike_valid_bucket.arn}/*",
      "${aws_s3_bucket.pipeline_spike_error_bucket.arn}",
      "${aws_s3_bucket.pipeline_spike_error_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "pipeline_spike_lambda" {
  name   = "pipeline_spike_lambda"
  role   = "${aws_iam_role.pipeline_spike_lambda.name}"
  policy = "${data.aws_iam_policy_document.pipeline_spike_lambda.json}"
}

resource "aws_lambda_function" "pipeline_spike_check_country" {
  filename         = "../artifacts/check_country.zip"
  function_name    = "pipeline_spike_check_country"
  role             = "${aws_iam_role.pipeline_spike_lambda.arn}"
  handler          = "check_country"
  source_code_hash = "${base64sha256(file("../artifacts/check_country.zip"))}"
  runtime          = "go1.x"
}

resource "aws_lambda_function" "pipeline_spike_catcher" {
  filename         = "../artifacts/catcher.zip"
  function_name    = "pipeline_spike_catcher"
  role             = "${aws_iam_role.pipeline_spike_lambda.arn}"
  handler          = "catcher"
  source_code_hash = "${base64sha256(file("../artifacts/catcher.zip"))}"
  runtime          = "go1.x"

  environment {
    variables = {
      PARTITION_KEY = "TODO"
      STREAM_NAME = "${aws_kinesis_stream.pipeline_spike_stream.name}"
    }
  }
}

resource "aws_lambda_function" "pipeline_spike_valid_putter" {
  filename         = "../artifacts/putter.zip"
  function_name    = "pipeline_spike_valid_putter"
  role             = "${aws_iam_role.pipeline_spike_lambda.arn}"
  handler          = "putter"
  source_code_hash = "${base64sha256(file("../artifacts/putter.zip"))}"
  runtime          = "go1.x"

  environment {
    variables = {
      S3_BUCKET = "${aws_s3_bucket.pipeline_spike_valid_bucket.id}"
      S3_REGION = "${aws_s3_bucket.pipeline_spike_valid_bucket.region}"
    }
  }
}

resource "aws_lambda_function" "pipeline_spike_error_putter" {
  filename         = "../artifacts/putter.zip"
  function_name    = "pipeline_spike_error_putter"
  role             = "${aws_iam_role.pipeline_spike_lambda.arn}"
  handler          = "putter"
  source_code_hash = "${base64sha256(file("../artifacts/putter.zip"))}"
  runtime          = "go1.x"

  environment {
    variables = {
      S3_BUCKET = "${aws_s3_bucket.pipeline_spike_error_bucket.id}"
      S3_REGION = "${aws_s3_bucket.pipeline_spike_error_bucket.region}"
    }
  }
}
