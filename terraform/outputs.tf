output "project_id" {
  description = "The created Project ID"
  value       = google_project.project.project_id
}

output "service_account_email" {
  description = "The email of the created Service Account"
  value       = google_service_account.terraform_sa.email
}

output "storage_bucket" {
  description = "The name of the GCS bucket"
  value       = google_storage_bucket.data-bucket.name
}

output "bigquery_dataset" {
  description = "The name of the BigQuery dataset"
  value       = google_bigquery_dataset.dataset.dataset_id
}

output "credentials_file" {
  description = "Location of the downloaded JSON credentials file"
  value       = local_sensitive_file.credentials_json.filename
}
