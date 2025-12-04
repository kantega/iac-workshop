module "s3_bucket" {
  source = "./modules/aws-s3-bucket"
  bucket_name = "uploads"
  username = local.username
  is_public = false
}