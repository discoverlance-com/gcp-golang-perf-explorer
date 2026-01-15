# Node.js Task App for Cloud Run

This is a simple Node.js application built with Express and EJS, using Google Cloud Firestore for storage. It is designed to be deployed on Google Cloud Run but can be deployed on any Docker enabled service.

## Features

- List tasks
- Create tasks
- Delete tasks
- Performance timing banner (server processing time)

## Prerequisites

- Node.js (v18+)
- Google Cloud Project with Firestore enabled
- Google Cloud SDK (gcloud) installed

## APIs to Enable

The following APIs must be enabled in your Google Cloud Project:

- **Cloud Trace API**: `cloudtrace.googleapis.com`
- **Cloud Logging API**: `logging.googleapis.com`
- **Cloud Monitoring API**: `monitoring.googleapis.com`
- **Telemetry API**: `telemetry.googleapis.com`

  ```bash
  gcloud services enable cloudtrace.googleapis.com logging.googleapis.com monitoring.googleapis.com telemetry.googleapis.com
  ```

## IAM Permissions

The user or service account running this application (locally or on Cloud Run) requires the following IAM roles:

- **Cloud Datastore User** (`roles/datastore.user`): To read and write to Firestore.
- **Logs Writer** (`roles/logging.logWriter`): To write logs to Cloud Logging.
- **Cloud Trace Agent** (`roles/cloudtrace.agent`): To write trace data.
- **Monitoring Metric Writer** (`roles/monitoring.metricWriter`): To write custom metrics.

## Setup

1. **Install dependencies:**

   ```bash
   npm install
   ```

2. **Environment Variables:**

   The application uses the following environment variables:

   - `PORT`: The port to listen on (default: 8080).
   - `DATABASE_ID`: The ID of the Firestore database. If using the `(default)` database, you can ommit this. For named databases, provide the database ID.

3. **Authentication:**

   For local development, ensure you are authenticated with Google Cloud:

   ```bash
   gcloud auth application-default login
   ```

## Running Locally

To run the application locally:

```bash
# Start the server (default port 8080)
npm start
```

or with a specific database ID:

```bash
# Linux/Mac
DATABASE_ID=my-database npm start

# Windows Powershell
$env:DATABASE_ID="my-database"; npm start
```

Visit `http://localhost:8080` in your browser.

## Deployment to Cloud Run

1. **Build the container image:**

   ```bash
   gcloud builds submit --tag gcr.io/PROJECT-ID/node-task-app
   ```

2. **Deploy to Cloud Run:**

   ```bash
   gcloud run deploy node-task-app \
     --image gcr.io/PROJECT-ID/node-task-app \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated \
     --set-env-vars DATABASE_ID=my-database
   ```

## docker build

```bash
docker build -t node-task-app .
docker run -p 8080:8080 -e GOOGLE_APPLICATION_CREDENTIALS=/path/to/creds.json -v /path/to/creds.json:/path/to/creds.json node-task-app
```
