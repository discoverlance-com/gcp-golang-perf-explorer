# GCP Golang vs Node.js Performance Explorer

This project is a performance comparison experiment between **Go** and **Node.js** running on **Google Cloud Run**.

It consists of two functionally identical applications (one in Go, one in Node.js) that interact with **Google Cloud Firestore**. Both applications are instrumented with **OpenTelemetry** to provide deep insights into latency and execution tracing via **Google Cloud Trace**.

## Project Structure

- `go-app/`: A Go 1.23+ web server using `gorilla/mux` and `html/template`.
- `node-app/`: A Node.js web server using `Express` and `EJS`.

## Goal

The goal is to deploy both applications to Cloud Run and measure:

1. **Cold Start Latency**: How fast does the container spin up and serve the first request?
2. **Runtime Performance**: How fast is the request processing (API handling + Template rendering)?
3. **Resource Usage**: Memory and CPU footprint difference.

## Prerequisites

To run these applications, you need a Google Cloud Project with the following configured.

### 1. APIs Enabled

Enable the necessary APIs for Trace, Logging, and Monitoring:

```bash
gcloud services enable \
  cloudtrace.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com
```

### 2. IAM Permissions

The Service Account (for Cloud Run) or User (for local dev) needs these roles:

- **Cloud Datastore User** (`roles/datastore.user`): To read/write tasks to Firestore.
- **Cloud Trace Agent** (`roles/cloudtrace.agent`): To upload trace data.
- **Logs Writer** (`roles/logging.logWriter`): To structured application logs.
- **Monitoring Metric Writer** (`roles/monitoring.metricWriter`): (Optional) For custom metrics.

If you deploy the application using gcloud CLI locally, ensure that the user account that was used to sign into the CLI has Cloud Run Admin, Artifact Registry Admin, Service Account User and Cloud Build Editor roles.

### 3. Firestore

Ensure your project has a Firestore database created in `Native` mode.

## Quick Start

1. **Clone the repository.**
2. **Navigate to the desired application folder** (`cd go-app` or `cd node-app`).
3. **Follow the specific README** in that folder to build and deploy.

## Performance Testing Idea

Once both services are deployed to Cloud Run, you can use a load testing tool like `hey` or `wrk` to generate traffic.

**Example Benchmark:**

```bash
# Test Node.js App
hey -n 1000 -c 50 https://node-app-url.run.app/

# Test Go App
hey -n 1000 -c 50 https://go-app-url.run.app/
```

Then, visit the **Google Cloud Console > Trace** to visualize the latency distributions and see the "waterfall" of spans for specific requests.

## Terraform Infrastructure for GCP Performance Explorer

The Terraform configuration in the /infra directory creates the Google Cloud Platform infrastructure needed to deploy and compare the performance of Go vs Node.js applications using Cloud Run, Firestore, and observability tools.

## Infrastructure Overview

This Terraform configuration provisions:

- **Google Cloud APIs**: Enables required services (Cloud Run, Firestore, Cloud Trace, etc.)
- **Firestore Database**: Native mode database for application data
- **Artifact Registry**: Docker repository with customer-managed encryption (CMEK)
- **KMS Key Management**: Encryption keys with 90-day rotation policy
- **Service Accounts**: Dedicated accounts for each application with appropriate IAM roles
- **Cloud Run Services**: Serverless container deployment with configurable authentication
- **IAM Permissions**: Least-privilege access for applications to GCP services

## Prerequisites

1. **Google Cloud Project**: Create a GCP project and note the project ID
2. **Terraform**: Install Terraform >= 1.0
3. **Google Cloud SDK**: Install and authenticate with `gcloud auth login`
4. **Billing**: Ensure billing is enabled on your GCP project

## Quick Start

### 1. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your project ID:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
environment = "dev"
```

### 2. Initialize and Apply Terraform

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 3. Build and Deploy Applications

After Terraform completes, use the output commands to build and deploy your applications:

```bash
# Configure Docker for Artifact Registry
terraform output -json build_commands | jq -r '.go_app.configure_docker'

# Build and push Go application
cd go-app
terraform output -json build_commands | jq -r '.go_app.build_and_push'

# Build and push Node.js application
cd ../node-app
terraform output -json build_commands | jq -r '.node_app.build_and_push'
```

### 4. Access Your Applications

Get the URLs from Terraform outputs:

```bash
# Get application URLs
terraform output go_app_url
terraform output node_app_url
```

## Configuration Reference

### Required Variables

| Variable     | Description             | Example            |
| ------------ | ----------------------- | ------------------ |
| `project_id` | Google Cloud Project ID | `"my-gcp-project"` |

### Optional Variables

| Variable                  | Description              | Default                  |
| ------------------------- | ------------------------ | ------------------------ |
| `region`                  | GCP region for resources | `"us-central1"`          |
| `environment`             | Environment name         | `"dev"`                  |
| `application_name`        | Application suite name   | `"performance-explorer"` |
| `firestore_database_id`   | Firestore database ID    | `"(default)"`            |
| `firestore_location_id`   | Firestore region         | `"nam5"`                 |
| `cloud_run_max_instances` | Max Cloud Run instances  | `10`                     |
| `cloud_run_memory`        | Memory per instance      | `"1Gi"`                  |
| `cloud_run_cpu`           | CPU per instance         | `"1"`                    |

## File Structure

```
├── terraform.tf           # Terraform and provider version constraints
├── providers.tf           # Provider configurations
├── variables.tf           # Input variable definitions
├── locals.tf             # Local values and computed variables
├── apis.tf               # Google Cloud API enablement
├── firestore.tf          # Firestore database configuration
├── artifact-registry.tf  # Container registry setup
├── iam.tf                # Service accounts and IAM roles
├── cloud-run.tf          # Cloud Run service definitions
├── outputs.tf            # Output values
└── terraform.tfvars.example # Example variable values
```

## Security Best Practices

This configuration implements comprehensive security best practices:

- **Customer-Managed Encryption**: Artifact Registry uses customer-managed encryption keys (CMEK)
- **Key Rotation**: KMS keys automatically rotate every 90 days for enhanced security
- **Configurable Authentication**: Cloud Run services support both authenticated and unauthenticated access modes
- **Least Privilege IAM**: Service accounts have only the minimum required permissions
- **Service Account Isolation**: Separate service accounts for each application
- **Resource Tagging**: All resources tagged for tracking and management
- **State Management**: Supports remote state storage in Google Cloud Storage
- **Security Scanning**: Passes all tfsec and checkov security checks

## Cost Optimization

- **Cold Start Optimization**: Cloud Run scales to zero when not in use
- **Resource Limits**: Appropriate CPU and memory limits set
- **Image Cleanup**: Artifact Registry cleanup policies remove old images

## Monitoring and Observability

The infrastructure enables comprehensive monitoring:

- **Cloud Trace**: Distributed tracing for performance analysis
- **Cloud Logging**: Structured logging for debugging
- **Cloud Monitoring**: Metrics and alerting capabilities

## Troubleshooting

### Common Issues

1. **API Not Enabled**: Run `terraform apply` again if you see API enablement errors
2. **Permissions**: Ensure your user has sufficient IAM permissions in the GCP project
3. **Quota Limits**: Check GCP quotas if resources fail to create

### Useful Commands

```bash
# Check Terraform state
terraform state list

# Get specific output
terraform output project_id

# Destroy infrastructure (use with caution)
terraform destroy
```

## Advanced Configuration

### Remote State Storage

To use remote state storage in Google Cloud Storage:

1. Create a GCS bucket for Terraform state
2. Uncomment and configure the backend in `terraform.tf`:

```hcl
backend "gcs" {
  bucket = "your-terraform-state-bucket"
  prefix = "performance-explorer/state"
}
```

### Multiple Environments

To deploy multiple environments:

1. Use Terraform workspaces: `terraform workspace new staging`
2. Or use separate variable files: `terraform apply -var-file="staging.tfvars"`

## Next Steps

After deploying the infrastructure:

1. **Build Applications**: Use the container build commands from outputs
2. **Performance Testing**: Use tools like `hey` or `wrk` to load test
3. **Monitor Results**: Check Cloud Trace for performance comparisons
4. **Optimize**: Adjust resource allocations based on performance data

## Support

For issues with this Terraform configuration:

1. Check the [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
2. Review [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
3. Consult [Google Cloud Firestore Documentation](https://cloud.google.com/firestore/docs)
