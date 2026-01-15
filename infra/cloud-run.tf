# Cloud Run service for Go application
resource "google_cloud_run_v2_service" "go_app" {
  project  = var.project_id
  name     = local.go_service_name
  location = var.region

  labels = local.common_labels

  template {
    # Service account for the application
    service_account = google_service_account.go_app.email

    # Scaling configuration
    scaling {
      max_instance_count = var.cloud_run_max_instances
      min_instance_count = 0
    }

    # Resource limits and requests
    containers {
      # Container image - using `us-docker.pkg.dev/cloudrun/container/hello` as a placeholder
      # to allow the service to be created. After creation, build actual image and deploy a new revision.
      # image = "${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_images.repository_id}/go-task-app:latest"
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      # Resource allocation
      resources {
        limits = {
          cpu    = var.cloud_run_cpu
          memory = var.cloud_run_memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      # Environment variables
      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }

      env {
        name  = "DATABASE_ID"
        value = var.firestore_database_id
      }


      # Health check configuration
      startup_probe {
        http_get {
          path = "/"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 10
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/"
          port = 8080
        }
        initial_delay_seconds = 30
        timeout_seconds       = 10
        period_seconds        = 30
        failure_threshold     = 3
      }

      # Container port
      ports {
        name           = "http1"
        container_port = 8080
      }
    }

    # Container concurrency
    max_instance_request_concurrency = var.cloud_run_concurrency

    # Request timeout
    timeout = var.cloud_run_timeout

    # Execution environment
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

    # Annotations for additional configuration
    annotations = {
      "autoscaling.knative.dev/maxScale"         = tostring(var.cloud_run_max_instances)
      "run.googleapis.com/execution-environment" = "gen2"
      "run.googleapis.com/cpu-throttling"        = "false"
    }
  }

  # Traffic configuration - 100% to latest revision
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    prevent_destroy = false # change to true to prevent accidental deletion
  }

  depends_on = [
    google_project_service.required_apis,
    google_service_account.go_app,
    google_artifact_registry_repository.container_images,
    google_firestore_database.main
  ]
}

# Cloud Run service for Node.js application
resource "google_cloud_run_v2_service" "node_app" {
  project  = var.project_id
  name     = local.node_service_name
  location = var.region

  labels = local.common_labels

  template {
    # Service account for the application
    service_account = google_service_account.node_app.email

    # Scaling configuration
    scaling {
      max_instance_count = var.cloud_run_max_instances
      min_instance_count = 0
    }

    # Resource limits and requests
    containers {
      # Container image - using `us-docker.pkg.dev/cloudrun/container/hello` as a placeholder
      # to allow the service to be created. After creation, build actual image and deploy a new revision.
      # image = "${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_images.repository_id}/node-task-app:latest"
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      # Resource allocation
      resources {
        limits = {
          cpu    = var.cloud_run_cpu
          memory = var.cloud_run_memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      # Environment variables
      env {
        name  = "DATABASE_ID"
        value = var.firestore_database_id
      }

      # Health check configuration
      startup_probe {
        http_get {
          path = "/"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 10
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/"
          port = 8080
        }
        initial_delay_seconds = 30
        timeout_seconds       = 10
        period_seconds        = 30
        failure_threshold     = 3
      }

      # Container port
      ports {
        name           = "http1"
        container_port = 8080
      }
    }

    # Container concurrency
    max_instance_request_concurrency = var.cloud_run_concurrency

    # Request timeout
    timeout = var.cloud_run_timeout

    # Execution environment
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

    # Annotations for additional configuration
    annotations = {
      "autoscaling.knative.dev/maxScale"         = tostring(var.cloud_run_max_instances)
      "run.googleapis.com/execution-environment" = "gen2"
      "run.googleapis.com/cpu-throttling"        = "false"
    }
  }

  # Traffic configuration - 100% to latest revision
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    prevent_destroy = false # change to true to prevent accidental deletion
  }

  depends_on = [
    google_project_service.required_apis,
    google_service_account.node_app,
    google_artifact_registry_repository.container_images,
    google_firestore_database.main
  ]
}

# Conditional IAM policy for unauthenticated access to Go service
resource "google_cloud_run_service_iam_member" "go_app_public" {
  count = var.allow_unauthenticated_access ? 1 : 0

  project  = var.project_id
  location = google_cloud_run_v2_service.go_app.location
  service  = google_cloud_run_v2_service.go_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Conditional IAM policy for unauthenticated access to Node.js service
resource "google_cloud_run_service_iam_member" "node_app_public" {
  count = var.allow_unauthenticated_access ? 1 : 0

  project  = var.project_id
  location = google_cloud_run_v2_service.node_app.location
  service  = google_cloud_run_v2_service.node_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# IAM policy for authorized users to access Go service
resource "google_cloud_run_service_iam_member" "go_app_authorized_users" {
  for_each = toset(var.authorized_users)

  project  = var.project_id
  location = google_cloud_run_v2_service.go_app.location
  service  = google_cloud_run_v2_service.go_app.name
  role     = "roles/run.invoker"
  member   = each.value
}

# IAM policy for authorized users to access Node.js service
resource "google_cloud_run_service_iam_member" "node_app_authorized_users" {
  for_each = toset(var.authorized_users)

  project  = var.project_id
  location = google_cloud_run_v2_service.node_app.location
  service  = google_cloud_run_v2_service.node_app.name
  role     = "roles/run.invoker"
  member   = each.value
}
