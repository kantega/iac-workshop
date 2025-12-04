
resource "aws_s3_bucket" "upload-bucket" {
  bucket = "${local.prefix}-bucket"

  tags = {
    Name        = "Martin sin bucket"
    Environment = "Test"
  }
}

# Get versioning on bucket
resource "aws_s3_bucket_versioning" "upload-bucket" {
  bucket = aws_s3_bucket.upload-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add encryption on bucket
resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_configuration" {
  bucket = aws_s3_bucket.upload-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "public-access-block" {
  bucket = aws_s3_bucket.upload-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}