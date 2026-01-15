# KMS Key Ring for encryption
resource "google_kms_key_ring" "artifact_registry" {
  project  = var.project_id
  name     = "${local.name_prefix}-artifact-registry-kr"
  location = var.artifact_registry_location

  depends_on = [
    google_project_service.required_apis
  ]
}

# KMS Crypto Key for Artifact Registry encryption
resource "google_kms_crypto_key" "artifact_registry" {
  name            = "${local.name_prefix}-artifact-registry-key"
  key_ring        = google_kms_key_ring.artifact_registry.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s" # 90 days in seconds

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = true
  }

  labels = local.common_labels
}

# IAM binding to allow Artifact Registry service account to use the key
resource "google_kms_crypto_key_iam_binding" "artifact_registry_encryption" {
  crypto_key_id = google_kms_crypto_key.artifact_registry.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.current.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
  ]
}

# Data source to get the current project
data "google_project" "current" {
  project_id = var.project_id
}
