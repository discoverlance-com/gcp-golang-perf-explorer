const pino = require("pino");

// Map Pino levels to Google Cloud Severity levels
const PinoLevelToSeverityLookup = {
  trace: "DEBUG",
  debug: "DEBUG",
  info: "INFO",
  warn: "WARNING",
  error: "ERROR",
  fatal: "CRITICAL",
};

const logger = pino({
  messageKey: "message",
  timestamp: () => `,"timestamp":"${new Date(Date.now()).toISOString()}"`,
  formatters: {
    log(object) {
      const { trace_id, span_id, trace_flags, ...rest } = object;

      // If OpenTelemetry injected trace context, format it for Google Cloud Logging
      const gcpLog = {
        ...rest,
      };

      if (trace_id) {
        gcpLog["logging.googleapis.com/trace"] = trace_id;
      }
      if (span_id) {
        gcpLog["logging.googleapis.com/spanId"] = span_id;
      }
      if (trace_flags) {
        gcpLog["logging.googleapis.com/trace_sampled"] = trace_flags === "01";
      }

      return gcpLog;
    },
    level(label) {
      return {
        severity:
          PinoLevelToSeverityLookup[label] || PinoLevelToSeverityLookup["info"],
      };
    },
  },
});

module.exports = logger;
