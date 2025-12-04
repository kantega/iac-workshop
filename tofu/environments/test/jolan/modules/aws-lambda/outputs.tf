output "lambda_function_arn" {
  description = "The ARN of the lambda function"
  value       = aws_lambda_function.this.arn
}
output "lambda_function_name" {
  description = "The name of the lambda function"
  value       = aws_lambda_function.this.function_name
}