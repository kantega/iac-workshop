data "aws_iam_role" "lambda_execution_role" {
  name = "iacws-lambda-role"
}

# Lambda function
resource "aws_lambda_function" "test-lambdafunc" {
  function_name    = "acws-eiralv-lambda"
  role = data.aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  s3_bucket = "iacws-package-bucket"
  s3_key = "s3-to-dynamo/package.zip"
  runtime = "nodejs22.x"
  timeout = 30
  memory_size = 256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.basic-dynamodb-table.name
    }
  }
}