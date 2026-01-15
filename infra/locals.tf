# Local values for consistent resource naming and configuration
locals {
  # Common resource naming
  name_prefix = "${var.application_name}-${var.environment}"

  # Common labels applied to all resources
  common_labels = {
    environment = var.environment
    application = var.application_name
    managed_by  = "terraform"
    project     = var.project_id
  }

  # Service account names
  go_app_sa_name   = "${local.name_prefix}-go-app"
  node_app_sa_name = "${local.name_prefix}-node-app"

  # Cloud Run service names
  go_service_name   = "${local.name_prefix}-go-app"
  node_service_name = "${local.name_prefix}-node-app"

  # Artifact Registry repository name
  artifact_repo_name = "${local.name_prefix}-images"

  # Required Google Cloud APIs
  required_apis = [
    "cloudtrace.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "firestore.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudkms.googleapis.com"
  ]

  # IAM roles for service accounts
  service_account_roles = [
    "roles/datastore.user",
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ]
}