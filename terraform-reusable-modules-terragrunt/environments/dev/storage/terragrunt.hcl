include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules/storage"
}

inputs = {
  bucket_name        = "${include.root.locals.name_prefix}-assets"
  versioning_enabled = true
  tags               = include.root.locals.common_tags
}
