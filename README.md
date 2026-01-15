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
