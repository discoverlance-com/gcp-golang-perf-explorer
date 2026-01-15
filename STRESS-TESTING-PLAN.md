# STRESS TESTING PLAN

## **Phase 1: Cold Start Analysis**

Cloud Run scales to zero. One of Go's theoretical advantages is faster startup time compared to Node.js.

**Test Goal:** Measure how long the _very first_ request takes after the service has been idle.
**Method:**

1. Wait 15 minutes (or manually delete the active revisions/instances in Cloud Console).
2. Send a single request to the Trace-heavy endpoint (Home `/`).
3. Repeat 5 times (waiting in between).

**Metrics to watch in Cloud Trace:**

- **Startup Latency**: Look for spans labeled `app_startup` or similar system spans in Cloud Trace.
- **Total Request Duration**: The wall-clock time from the client's perspective.

## **Phase 2: Throughput & Latency (Steady State)**

This measures raw speed when the container is already warm.

**Test Goal:** Compare P50 (median) and P99 (tail) latency under load.
**Tools:** `hey` (simple) or `k6` (scriptable).

**Scenario A: "The Render Test" (GET /)**
This tests Firestore Read + Template Rendering (Go `html/template` vs Node `EJS`).

```bash
# Concurrency: 50, Duration: 30s
hey -n 2000 -c 50 https://go-explorer-xyz.run.app/
hey -n 2000 -c 50 https://node-explorer-xyz.run.app/
```

**Scenario B: "The Overhead Test" (GET /ping)**
This tests the raw http server overhead (Net/Http vs Express) without DB noise.

```bash
hey -n 5000 -c 100 https://go-explorer-xyz.run.app/ping
hey -n 5000 -c 100 https://node-explorer-xyz.run.app/ping
```

## **Phase 3: Resource Efficiency**

Cloud Run charges by vCPU/Memory second. If Go uses less memory, you can potentially run it on a smaller instance size (e.g., 128MB vs 512MB) to save money.

**Method:**

1. Run a sustained load (e.g., 5 minutes of constant traffic).
2. Open **Cloud Monitoring**.
3. Compare:
   - **Container Memory Utilization**: Node usually sits around 40-70MB idle. Go binary acts are often smaller (10-20MB).
   - **Container CPU Utilization**: See which handles the specific Requests Per Second (RPS) with less CPU % usage.

## **Phase 4: Concurrency Handling (The "Go Routine" Advantage)**

Go's concurrency model (Goroutines) typically handles high concurrency better than Node's single-threaded Event Loop (which is great for I/O but can block on CPU tasks like template rendering).

**Test Goal:** Break the services. Find the RPS tipping point where latency skyrockets.

**Method:**
Run `k6` ramping up VUs (Virtual Users) until 504 errors occur.

```javascript
// k6-script.js
import http from "k6/http";
import { check } from "k6";

export let options = {
  stages: [
    { duration: "30s", target: 50 }, // Ramp to 50 users
    { duration: "1m", target: 200 }, // Stress: 200 concurrent users
    { duration: "30s", target: 0 }, // Cooldown
  ],
};

export default function () {
  let res = http.get("https://YOUR_URL.run.app/");
  check(res, { "status is 200": (r) => r.status === 200 });
}
```

## **How to Analyze the Results**

1. **Latency Distribution (Console output):**

   - Go often has a "tighter" distribution (lower standard deviation).
   - Node might show higher P99 spikes due to Garbage Collection (GC) pauses under load.

2. **Cloud Trace "Waterfall":**
   - Go to **Trace > Trace List**.
   - Filter by URI `/`.
   - Compare the **Span Duration** of the template rendering logic.
   - Check the visual gap between "Request Received" and "Firestore Query Start" (Framework overhead).

## **Checklist for Fairness**

- **Region:** Ensure both apps are in the same region (`us-central1`).
- **Instance Class:** Ensure both Cloud Run services are using the same specs (e.g., 1 CPU, 512MB Memory) and "Maximum Concurrency" settings (default is usually 80).
- **Database:** Ensure they are querying the same Firestore collection size (Populate 100 items in both DBs so the render work is identical).
