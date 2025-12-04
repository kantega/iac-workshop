resource "aws_s3_bucket" "sigodo-uploads" {
  bucket = "iacws-sigodo-uploads"

  tags = {
    Name        = "Blorpo"
    Environment = "Test"
  }
}

resource "aws_s3_bucket_versioning" "sigodo-uploads" {
  bucket = aws_s3_bucket.sigodo-uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sigodo-uploads" {
  bucket = aws_s3_bucket.sigodo-uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_public_access_block" "sigodo-uploads" {
  bucket = aws_s3_bucket.sigodo-uploads.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
