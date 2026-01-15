# GCP Golang vs Node.js Performance Explorer

This project is a performance comparison experiment between **Go** and **Node.js** running on **Google Cloud Run**.

It consists of two functionally identical applications (one in Go, one in Node.js) that interact with **Google Cloud Firestore**. Both applications are instrumented with **OpenTelemetry** to provide deep insights into latency and execution tracing via **Google Cloud Trace**.

## Project Structure

- `go-app/`: A Go web server using `gorilla/mux` and `html/template`.
- `node-app/`: A Node.js web server using `Express` and `EJS`.
- `infra/`: Terraform configuration to provision the Google Cloud environment (Cloud Run, Firestore, Artifact Registry, etc.).

## Goal

The goal is to deploy both applications to Cloud Run and measure:

1. **Cold Start Latency**: How fast does the container spin up and serve the first request?
2. **Runtime Performance**: How fast is the request processing (API handling + Template rendering)?
3. **Resource Usage**: Memory and CPU footprint difference.

## Prerequisites

To run these applications, you need a Google Cloud Project. You can set this up manually or use the provided Terraform infrastructure.

### Option 1: Infrastructure as Code (Recommended)

See the [Infrastructure README](infra/README.md) for instructions on how to provision the entire environment using Terraform.

### Option 2: Manual Setup

1. **Enable APIs**: `cloudtrace.googleapis.com`, `logging.googleapis.com`, `monitoring.googleapis.com`.
2. **IAM Roles**: Ensure your deployer has `Cloud Run Admin`, `Artifact Registry Admin` (for source deploy), and `Service Account User`.
3. **Firestore**: Create a `Native` mode database.

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
