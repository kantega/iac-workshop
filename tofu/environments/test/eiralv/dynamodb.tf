resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name         = "iacws-eiralv-dynamodb"
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing, no capacity planning needed
  hash_key     = "id"

  attribute {
      name = "id"
      type = "S"
  }

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
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}