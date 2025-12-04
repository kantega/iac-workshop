
variable "lambda_name" {
  description = "The name of the Lambda function to be triggered by S3 events"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket that will trigger the Lambda function"
  type        = string
}