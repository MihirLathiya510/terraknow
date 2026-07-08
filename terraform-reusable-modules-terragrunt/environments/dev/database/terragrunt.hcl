include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules/database"
}

inputs = {
  table_name   = "${include.root.locals.name_prefix}-urls"
  hash_key     = "short_code"
  billing_mode = "PAY_PER_REQUEST"
  tags         = include.root.locals.common_tags
}
