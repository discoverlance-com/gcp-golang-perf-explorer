# Artifact Registry Repository for container images
resource "google_artifact_registry_repository" "container_images" {
  project       = var.project_id
  location      = var.artifact_registry_location
  repository_id = local.artifact_repo_name
  description   = "Container image repository for ${var.application_name} applications"
  format        = "DOCKER"

  labels = local.common_labels

  # Customer-managed encryption key
  kms_key_name = google_kms_crypto_key.artifact_registry.id

  # Ensure APIs and KMS key are ready before creating the repository
  depends_on = [
    google_project_service.required_apis,
    google_kms_crypto_key_iam_binding.artifact_registry_encryption
  ]

  # Cleanup policy to manage repository size
  cleanup_policy_dry_run = false
  cleanup_policies {
    id     = "keep-recent-versions"
    action = "DELETE"

    condition {
      tag_state  = "TAGGED"
      newer_than = "604800s" # 7 days
    }

    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"

    condition {
      tag_state  = "UNTAGGED"
      newer_than = "86400s" # 1 day
    }
  }
}