module "storage" {
  source = "../../modules/storage"

  bucket_name        = "${local.name_prefix}-assets"
  versioning_enabled = true
  tags               = local.common_tags
}

module "database" {
  source = "../../modules/database"

  table_name   = "${local.name_prefix}-urls"
  hash_key     = "short_code"
  billing_mode = var.billing_mode
  tags         = local.common_tags
}
