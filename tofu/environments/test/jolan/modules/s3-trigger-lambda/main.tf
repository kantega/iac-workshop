data "aws_s3_bucket" "this" {
  bucket = var.s3_bucket_name
}

data "aws_lambda_function" "this" {
  function_name = var.lambda_name
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.this.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = data.aws_s3_bucket.this.id

  lambda_function {
    lambda_function_arn = data.aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}