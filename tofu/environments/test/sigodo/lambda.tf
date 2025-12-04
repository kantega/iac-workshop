data "aws_iam_role" "lambda_execution_role" {
  name = "iacws-lambda-role"
}

resource "aws_lambda_function" "s3_processor" {
  function_name    = "iacws-s3-processor-${local.username}"
  role            = data.aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  s3_bucket = "iacws-package-bucket"
  s3_key = "s3-to-dynamo/package.zip"
  runtime         = "nodejs22.x"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.json_data.name
    }
  }
}