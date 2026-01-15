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

# Firestore index for tasks collection (optional but recommended for performance)
resource "google_firestore_index" "tasks_index" {
  project    = var.project_id
  database   = google_firestore_database.main.name
  collection = "tasks"

  fields {
    field_path = "created"
    order      = "DESCENDING"
  }

  fields {
    field_path = "__name__"
    order      = "DESCENDING"
  }

  depends_on = [
    google_firestore_database.main
  ]
}