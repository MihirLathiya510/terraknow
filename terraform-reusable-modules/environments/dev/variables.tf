variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod."
  }
}

variable "project_name" {
  description = "Project name used as a naming prefix"
  type        = string
}

variable "billing_mode" {
  description = "DynamoDB billing mode for this environment"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "tags" {
  description = "Common tags applied to all resources in this environment"
  type        = map(string)
  default     = {}
}
