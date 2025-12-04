data "aws_iam_role" "lambda_execution_role" {
  name = "iacws-lambda-role"
}

locals {
  username = "jolan" # Replace with your username
  prefix = "iacws-${local.username}"
  s3_bucket = "iacws-package-bucket"
  default_handler = "index.handler"
  default_runtime = "nodejs22.x"
}

resource "aws_lambda_function" "this" {
  function_name = "${local.prefix}-${var.function_name}"
  s3_bucket     = local.s3_bucket
  s3_key        = "${var.package_name}/package.zip"
  handler       = local.default_handler
  runtime       = local.default_runtime
  role          = data.aws_iam_role.lambda_execution_role.arn
  environment {
    variables = var.environment_variables
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  count = var.enable_logging ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 7
}