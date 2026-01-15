# Service Account for Go Application
resource "google_service_account" "go_app" {
  project      = var.project_id
  account_id   = local.go_app_sa_name
  display_name = "Service Account for Go Task App"
  description  = "Service account used by the Go application on Cloud Run for accessing GCP services"
}

# Service Account for Node.js Application
resource "google_service_account" "node_app" {
  project      = var.project_id
  account_id   = local.node_app_sa_name
  display_name = "Service Account for Node.js Task App"
  description  = "Service account used by the Node.js application on Cloud Run for accessing GCP services"
}

# IAM role bindings for Go application service account
resource "google_project_iam_member" "go_app_roles" {
  for_each = toset(local.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.go_app.email}"

  depends_on = [
    google_service_account.go_app
  ]
}

# IAM role bindings for Node.js application service account
resource "google_project_iam_member" "node_app_roles" {
  for_each = toset(local.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.node_app.email}"

  depends_on = [
    google_service_account.node_app
  ]
}

# Additional role for Artifact Registry access (for Cloud Build)
resource "google_project_iam_member" "artifact_registry_reader" {
  for_each = toset([
    google_service_account.go_app.email,
    google_service_account.node_app.email
  ])

  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${each.value}"
}