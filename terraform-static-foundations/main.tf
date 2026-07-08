resource "aws_s3_bucket" "static_site" {
  bucket = "${var.bucket_name_prefix}-${var.environment}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.bucket_name_prefix}-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_s3_bucket_versioning" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  versioning_configuration {
    status = "Enabled"
  }
}