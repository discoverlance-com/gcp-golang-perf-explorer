const { GrpcInstrumentation } = require("@opentelemetry/instrumentation-grpc");
// Manually initialize gRPC instrumentation before requiring any other modules that might use it
const grpcInstrumentation = new GrpcInstrumentation();
grpcInstrumentation.enable();

const { NodeSDK } = require("@opentelemetry/sdk-node");
const {
  getNodeAutoInstrumentations,
} = require("@opentelemetry/auto-instrumentations-node");
const {
  TraceExporter,
} = require("@google-cloud/opentelemetry-cloud-trace-exporter");
const { diag, DiagConsoleLogger, DiagLogLevel } = require("@opentelemetry/api");

// Setup detailed diagnostics for OpenTelemetry itself (configured via env var OTEL_LOG_LEVEL)
diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.INFO);

// Enable OpenTelemetry
const sdk = new NodeSDK({
  traceExporter: new TraceExporter(),
  instrumentations: [
    getNodeAutoInstrumentations({
      // Disable noisy instrumentations if needed
      "@opentelemetry/instrumentation-fs": { enabled: false },
      // Disable auto-instrumentation for grpc since we enabled it manually above
      "@opentelemetry/instrumentation-grpc": { enabled: false },
    }),
  ],
});

try {
  sdk.start();
  console.log("OpenTelemetry instrumentation started successfully");
} catch (error) {
  console.error("Error initializing OpenTelemetry SDK", error);
}

// Graceful shutdown
process.on("SIGTERM", () => {
  sdk
    .shutdown()
    .then(() => console.log("OpenTelemetry SDK terminated"))
    .catch((error) =>
      console.error("Error terminating OpenTelemetry SDK", error)
    );
});

console.log("OpenTelemetry instrumentation started");
