output "bucket_name" {
  description = "Name of the assets bucket for this environment"
  value       = module.storage.bucket_name
}

output "table_name" {
  description = "Name of the URL mapping table for this environment"
  value       = module.database.table_name
}
