variable "project" {
  description = "Your GCP Project ID"
}

variable "billing_account_id" {
  description = "The GCP billing account ID"
}

variable "sa_name" {
  description = "The name for the Terraform service account"
}

variable "region" {
  description = "Region for GCP resources"
  default     = "us-central1"
}

variable "location" {
  description = "Project Location"
  default     = "US"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
}

variable "gcs_bucket_name" {
  description = "The Cloud Storage Bucket Name"
}
