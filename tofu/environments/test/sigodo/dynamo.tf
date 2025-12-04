# DynamoDB table for storing JSON data
resource "aws_dynamodb_table" "json_data" {
  name         = "iacws-json-data-sigodo"
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