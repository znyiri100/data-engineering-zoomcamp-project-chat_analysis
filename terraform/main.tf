terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  region = var.region
}

# 1. Create the GCP Project and link billing
resource "google_project" "project" {
  name            = var.project
  project_id      = var.project
  billing_account = var.billing_account_id
}

# 2. Enable necessary APIs
resource "google_project_service" "services" {
  for_each = toset([
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com"
  ])

  project            = google_project.project.project_id
  service            = each.key
  disable_on_destroy = false
}

# 3. Create a Service Account for Terraform
resource "google_service_account" "terraform_sa" {
  account_id   = var.sa_name
  display_name = var.sa_name
  project      = google_project.project.project_id

  depends_on = [google_project_service.services]
}

# 4. Grant necessary roles to the Service Account
resource "google_project_iam_member" "sa_roles" {
  for_each = toset([
    "roles/storage.admin",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser"
  ])
  project = google_project.project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# 5. Disable the Policy Constraint preventing service account key creation
resource "google_project_organization_policy" "disable_key_creation" {
  project    = google_project.project.project_id
  constraint = "iam.disableServiceAccountKeyCreation"

  boolean_policy {
    enforced = false
  }

  depends_on = [google_project_service.services]
}

# 6. Generate the JSON credentials key
resource "google_service_account_key" "terraform_sa_key" {
  service_account_id = google_service_account.terraform_sa.name

  # Must ensure the policy is disabled before creating the key
  depends_on = [google_project_organization_policy.disable_key_creation]
}

# 7. Save the JSON key locally for pipeline access
resource "local_sensitive_file" "credentials_json" {
  content  = base64decode(google_service_account_key.terraform_sa_key.private_key)
  filename = "${path.module}/../.credentials.json"
}

# Google Cloud Storage Bucket
resource "google_storage_bucket" "data-bucket" {
  project                     = google_project.project.project_id
  name                        = var.gcs_bucket_name
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }

  depends_on = [google_project_service.services]
}

# BigQuery Dataset
resource "google_bigquery_dataset" "dataset" {
  project                    = google_project.project.project_id
  dataset_id                 = replace(var.bq_dataset_name, "-", "_")
  location                   = var.location
  delete_contents_on_destroy = true

  depends_on = [google_project_service.services]
}
