variable "bucket_name" {
  description = "Full name of the S3 bucket (caller is responsible for uniqueness)"
  type        = string
}

variable "versioning_enabled" {
  description = "Whether to enable versioning on the bucket"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
