# Project Information
output "project_id" {
  description = "The Google Cloud project ID"
  value       = var.project_id
}

output "region" {
  description = "The Google Cloud region"
  value       = var.region
}

# Firestore Information
output "firestore_database_name" {
  description = "The name of the Firestore database"
  value       = google_firestore_database.main.name
}

output "firestore_database_id" {
  description = "The ID of the Firestore database"
  value       = google_firestore_database.main.name
}

# Artifact Registry Information
output "artifact_registry_repository" {
  description = "The Artifact Registry repository name"
  value       = google_artifact_registry_repository.container_images.repository_id
}

output "artifact_registry_url" {
  description = "The full URL of the Artifact Registry repository"
  value       = "${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_images.repository_id}"
}

# Service Account Information
output "go_app_service_account_email" {
  description = "Email of the Go application service account"
  value       = google_service_account.go_app.email
}

output "node_app_service_account_email" {
  description = "Email of the Node.js application service account"
  value       = google_service_account.node_app.email
}

# Cloud Run Service Information
output "go_app_url" {
  description = "URL of the deployed Go application"
  value       = google_cloud_run_v2_service.go_app.uri
}

output "node_app_url" {
  description = "URL of the deployed Node.js application"
  value       = google_cloud_run_v2_service.node_app.uri
}

output "go_app_service_name" {
  description = "Name of the Go Cloud Run service"
  value       = google_cloud_run_v2_service.go_app.name
}

output "node_app_service_name" {
  description = "Name of the Node.js Cloud Run service"
  value       = google_cloud_run_v2_service.node_app.name
}

# Container Image Build Information
output "go_app_image_url" {
  description = "Full container image URL for Go application"
  value       = "${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_images.repository_id}/go-task-app:latest"
}

output "node_app_image_url" {
  description = "Full container image URL for Node.js application"
  value       = "${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_images.repository_id}/node-task-app:latest"
}

# Security Configuration Information
output "security_configuration" {
  description = "Current security configuration"
  value = {
    unauthenticated_access_enabled = var.allow_unauthenticated_access
    authorized_users_count         = length(var.authorized_users)
    kms_key_id                     = google_kms_crypto_key.artifact_registry.id
    encryption_status              = "Customer-managed encryption enabled"
  }
}

# Build and Deploy Commands
output "build_commands" {
  description = "Commands to build and push container images"
  value = {
    go_app = {
      configure_docker = "gcloud auth configure-docker ${var.artifact_registry_location}-docker.pkg.dev"
      build_and_push   = "cd go-app && gcloud builds submit --tag ${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_images.repository_id}/go-task-app:latest"
    }
    node_app = {
      configure_docker = "gcloud auth configure-docker ${var.artifact_registry_location}-docker.pkg.dev"
      build_and_push   = "cd node-app && gcloud builds submit --tag ${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_images.repository_id}/node-task-app:latest"
    }
  }
}

# Access Commands (when authentication is required)
output "access_commands" {
  description = "Commands to access services when authentication is required"
  value = {
    get_auth_token = "gcloud auth print-identity-token"
    curl_go_app    = "curl -H 'Authorization: Bearer $(gcloud auth print-identity-token)' ${google_cloud_run_v2_service.go_app.uri}"
    curl_node_app  = "curl -H 'Authorization: Bearer $(gcloud auth print-identity-token)' ${google_cloud_run_v2_service.node_app.uri}"
  }
}