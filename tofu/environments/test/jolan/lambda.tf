module "process_s3_to_dynamo" {
  source = "./modules/aws-lambda"
  function_name = "s3-to-dynamo"
  package_name  = "s3-to-dynamo"
  username = local.username
  environment_variables = {
    DYNAMODB_TABLE_NAME = aws_dynamodb_table.json_data.name
  }
  enable_logging = true
}

module "trigger_lambda" {
  source = "./modules/s3-trigger-lambda"
  lambda_name = module.process_s3_to_dynamo.lambda_function_name
  s3_bucket_name = module.s3_bucket.bucket_name

  depends_on = [module.process_s3_to_dynamo, module.s3_bucket]
}