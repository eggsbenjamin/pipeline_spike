resource "aws_iam_role" "pipeline_spike_step_fn" {
  name = "pipeline_spike_step_fn"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "states.eu-west-1.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "pipeline_spike_step_fn" {
  name   = "pipeline_spike_step_fn"
  role   = "${aws_iam_role.pipeline_spike_step_fn.name}"
  policy = "${data.aws_iam_policy_document.pipeline_spike_step_fn.json}"
}

data "aws_iam_policy_document" "pipeline_spike_step_fn" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "${aws_lambda_function.pipeline_spike_check_country.arn}",
      "${aws_lambda_function.pipeline_spike_catcher.arn}",
      "${aws_lambda_function.pipeline_spike_valid_putter.arn}",
      "${aws_lambda_function.pipeline_spike_error_putter.arn}"
    ]
  }
}

resource "aws_sfn_state_machine" "pipeline_spike_step_fn" {
  name     = "pipeline_spike_step_fn"
  role_arn = "${aws_iam_role.pipeline_spike_step_fn.arn}"

  definition = <<EOF
{
  "Comment": "Pipeline Spike Step Function",
  "StartAt": "CheckCountry",
  "States": {
    "CheckCountry" : {
      "Type": "Task",
      "Resource": "${aws_lambda_function.pipeline_spike_check_country.arn}",
      "Next": "ValidOrderPutter",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 1,
          "BackoffRate": 2.0,
          "MaxAttempts": 2
        }
      ],
      "Catch": [ 
        {
          "ErrorEquals": [ 
            "ErrInvalidCountryCode"
          ],
          "ResultPath": "$.error",
          "Next": "ErrorOrderPutter"
        },
        {
          "ErrorEquals": [ 
            "States.ALL"
          ],
          "ResultPath": "$.error",
          "Next": "Catcher"
        } 
      ]
    },
    "ValidOrderPutter" : {
      "Type": "Task",
      "Resource": "${aws_lambda_function.pipeline_spike_valid_putter.arn}",
      "End" : true,
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 1,
          "BackoffRate": 2.0,
          "MaxAttempts": 2
        }
      ],
      "Catch": [ 
        {
          "ErrorEquals": [ 
            "States.ALL"
          ],
          "ResultPath": "$.error",
          "Next": "Catcher"
        } 
      ]
    },
    "ErrorOrderPutter" : {
      "Type": "Task",
      "Resource": "${aws_lambda_function.pipeline_spike_error_putter.arn}",
      "End" : true,
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 1,
          "BackoffRate": 2.0,
          "MaxAttempts": 2
        }
      ],
      "Catch": [ 
        {
          "ErrorEquals": [ 
            "States.ALL"
          ],
          "ResultPath": "$.error",
          "Next": "Catcher"
        } 
      ]
    },
    "Catcher" : {
      "Type": "Task",
      "Resource": "${aws_lambda_function.pipeline_spike_catcher.arn}",
      "End" : true,
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 2,
          "BackoffRate": 2.0,
          "MaxAttempts": 10
        }
      ],
      "Catch": [ 
        {
          "ErrorEquals": [ 
            "States.ALL"
          ],
          "ResultPath": "$.error",
          "Next": "Catcher"
        } 
      ]
    }
  }

}
EOF
}
