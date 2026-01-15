# Go Task App for Cloud Run

This is a simple Go application built with `net/http`, `gorilla/mux` and `HTML templates`, using Google Cloud Firestore for storage. It is designed to be deployed on Google Cloud Run but can be deployed on any Docker enabled service.

## Features

- List tasks
- Create tasks
- Delete tasks
- Performance timing banner (server processing time)
- OpenTelemetry Instrumentation (Cloud Trace, Cloud Logging)

## Prerequisites

- Go (v1.23+)
- Google Cloud Project with Firestore enabled
- Google Cloud SDK (gcloud) installed

## Cloud Setup

Please refer to the [Root README](../README.md) for details on:

- APIs to Enable (Cloud Trace, Logging, etc.)
- IAM Permissions required

## Setup

1. **Install dependencies:**

   ```bash
   cd go-app
   go mod tidy
   ```

2. **Environment Variables:**

   The application uses the following environment variables:

   - `PORT`: The port to listen on (default: 8080).
   - `GOOGLE_CLOUD_PROJECT`: The ID of your Google Cloud Project.
   - `DATABASE_ID`: The ID of the Firestore database. If using the `(default)` database, you can ommit this (or set it to `(default)`).

   You can create a `.env` file in the root directory to set these variables locally:

   ```env
   GOOGLE_CLOUD_PROJECT=your-project-id
   DATABASE_ID=(default)
   ```

3. **Authentication:**

   For local development, ensure you are authenticated with Google Cloud:

   ```bash
   gcloud auth application-default login
   ```

## Running Locally

To run the application locally:

```bash
# Start the server (default port 8080)
go run .
```

or with a specific database ID override:

```bash
# Linux/Mac
DATABASE_ID=my-database go run .

# Windows Powershell
$env:DATABASE_ID="my-database"; go run .
```

Visit `http://localhost:8080` in your browser.

## Deployment to Cloud Run

1. **Build the container image:**

   ```bash
   gcloud builds submit --tag gcr.io/PROJECT-ID/go-task-app
   ```

2. **Deploy to Cloud Run:**

   ```bash
   gcloud run deploy go-task-app \
     --image gcr.io/PROJECT-ID/go-task-app \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated \
     --set-env-vars GOOGLE_CLOUD_PROJECT=PROJECT-ID,DATABASE_ID=(default)
   ```

## Docker Build

```bash
docker build -t go-task-app .
# Note: You need to pass credentials to the container for it to access Google Cloud services locally
docker run -p 8080:8080 \
  -e GOOGLE_CLOUD_PROJECT=your-project-id \
  -v $HOME/.config/gcloud/application_default_credentials.json:/tmp/keys/creds.json:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/tmp/keys/creds.json \
  go-task-app
```
