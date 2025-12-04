resource "aws_dynamodb_table" "json_data" {
  name = "iacws-json-data-gorbas"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "s3Key"
    type = "S"
  }

  global_secondary_index {
    name = "S3KeyIndex"
    hash_key = "s3Key"
    projection_type = "ALL"
  }
}