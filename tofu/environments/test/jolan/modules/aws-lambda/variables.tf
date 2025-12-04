variable "function_name" {
  description = "The name of the lambda function"
  type        = string
}

variable "username" {
  description = "The username for prefixing resources"
  type        = string
}

variable "package_name" {
  description = "The name of the package in the s3 bucket"
  type        = string
}
variable "environment_variables" {
  description = "A map of environment variables for the lambda function"
  type        = map(string)
  default     = {}
}
variable "enable_logging" {
  description = "Whether to enable CloudWatch logging for the lambda function"
  type        = bool
  default     = true
}