variable "table_name" {
  description = "Full name of the DynamoDB table"
  type        = string
}

variable "hash_key" {
  description = "Name of the hash (partition) key attribute"
  type        = string
  default     = "short_code"
}

variable "billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "tags" {
  description = "Tags to apply to the table"
  type        = map(string)
  default     = {}
}
