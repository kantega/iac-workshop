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
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.json_data.name
    }
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.upload_bucket.arn
}