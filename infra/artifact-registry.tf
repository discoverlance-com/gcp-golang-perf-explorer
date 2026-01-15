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

  # Policy 1: Keep the most recent 10 versions (protects them from deletion)
  cleanup_policies {
    id     = "keep-recent-versions"
    action = "KEEP"

    most_recent_versions {
      keep_count = 10
    }
  }

  # Policy 2: Delete tagged versions older than 7 days (subject to KEEP rules above)
  cleanup_policies {
    id     = "delete-old-versions"
    action = "DELETE"

    condition {
      tag_state  = "TAGGED"
      older_than = "604800s" # 7 days
    }
  }

  # Policy 3: Delete untagged versions older than 1 day
  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"

    condition {
      tag_state  = "UNTAGGED"
      older_than = "86400s" # 1 day
    }
  }
}
