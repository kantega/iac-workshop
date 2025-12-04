terraform {
  backend "s3" {
    bucket = "iacws-state-test"
    key = "test/gorbas/terraform.tfstate"
    region = "eu-north-1"
    profile = "iacws"
    use_lockfile = true
    encrypt = true
  }
}