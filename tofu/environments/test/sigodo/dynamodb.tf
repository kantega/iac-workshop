resource "aws_dynamodb_table" "sigodo-table" {
  name = "iacws-sigodo-table"

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
}