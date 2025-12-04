variable "username" {
  description = "The username for prefixing resources"
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "is_public" {
  description = "Whether the S3 bucket is public"
  type        = bool
  default     = false
}