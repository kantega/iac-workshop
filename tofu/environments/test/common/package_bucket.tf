resource "aws_s3_bucket" "package_bucket" {
  bucket = "iacws-package-bucket"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "package_bucket" {
  bucket = aws_s3_bucket.package_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "package_bucket" {
  bucket = aws_s3_bucket.package_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}