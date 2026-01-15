# Project Configuration
variable "project_id" {
  type        = string
  description = "The Google Cloud project ID where resources will be created"
}

variable "region" {
  type        = string
  description = "The Google Cloud region for resources"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "The Google Cloud zone for regional resources"
  default     = "us-central1-a"
}

# Application Configuration
variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
  default     = "dev"
}

variable "application_name" {
  type        = string
  description = "Name of the application suite"
  default     = "performance-explorer"
}

# Firestore Configuration
variable "firestore_database_id" {
  type        = string
  description = "Firestore database ID (use '(default)' for default database)"
  default     = "(default)"
}

variable "firestore_location_id" {
  type        = string
  description = "Firestore location ID"
  default     = "nam5"
}

# Container Registry Configuration
variable "artifact_registry_location" {
  type        = string
  description = "Location for Artifact Registry repository"
  default     = "us-central1"
}

# Cloud Run Configuration
variable "cloud_run_max_instances" {
  type        = number
  description = "Maximum number of instances for Cloud Run services"
  default     = 10
}

variable "cloud_run_memory" {
  type        = string
  description = "Memory allocation for Cloud Run services"
  default     = "1Gi"
}

variable "cloud_run_cpu" {
  type        = string
  description = "CPU allocation for Cloud Run services"
  default     = "1"
}

variable "cloud_run_concurrency" {
  type        = number
  description = "Maximum concurrent requests per Cloud Run instance"
  default     = 1000
}

variable "cloud_run_timeout" {
  type        = string
  description = "Request timeout for Cloud Run services"
  default     = "60s"
}

# Security Configuration
variable "allow_unauthenticated_access" {
  type        = bool
  description = "Allow unauthenticated access to Cloud Run services (set to false for production)"
  default     = false
}

variable "authorized_users" {
  type        = list(string)
  description = "List of users/service accounts authorized to invoke Cloud Run services"
  default     = []
}