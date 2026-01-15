# Enable required Google Cloud APIs
resource "google_project_service" "required_apis" {
  for_each = toset(local.required_apis)

  project = var.project_id
  service = each.value

  # Prevent disabling when destroying
  disable_on_destroy = false

  # Ensure services are enabled sequentially to avoid conflicts
  timeouts {
    create = "10m"
    update = "10m"
  }
}