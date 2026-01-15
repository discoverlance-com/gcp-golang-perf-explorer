# Firestore Database
resource "google_firestore_database" "main" {
  project     = var.project_id
  name        = var.firestore_database_id
  location_id = var.firestore_location_id
  type        = "FIRESTORE_NATIVE"

  # Ensure APIs are enabled before creating the database
  depends_on = [
    google_project_service.required_apis
  ]

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}
