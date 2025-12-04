# DynamoDB table for storing JSON data
resource "aws_dynamodb_table" "json_data" {
  name         = "iacws-json-data-jolan"
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing, no capacity planning needed
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Optional: Add a secondary index for querying by S3 key
  attribute {
    name = "s3Key"
    type = "S"
  }

  global_secondary_index {
    name            = "S3KeyIndex"
    hash_key        = "s3Key"
    projection_type = "ALL"
  }

  tags = {
    Name        = "JSON Data Table"
    Purpose     = "Store JSON data from S3 uploads"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.upload_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}