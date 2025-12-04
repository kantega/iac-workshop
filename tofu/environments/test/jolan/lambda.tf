module "process_s3_to_dynamo" {
  source = "./modules/aws-lambda"
  function_name = "s3-to-dynamo"
  package_name  = "s3-to-dynamo"
  environment_variables = {
    DYNAMODB_TABLE_NAME = aws_dynamodb_table.<your_table>.name
  }
  enable_logging = true
}

function = module.process_s3_to_dynamo.lambda_function_name