package main

import (
	"context"
	"errors"
	"log/slog"
	"os"

	texporter "github.com/GoogleCloudPlatform/opentelemetry-operations-go/exporter/trace"
	"go.opentelemetry.io/contrib/detectors/gcp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	"go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
)

func setupOpenTelemetry(ctx context.Context) (shutdown func(context.Context) error, err error) {
	var shutdownFuncs []func(context.Context) error

	// shutdown combines shutdown functions from multiple OpenTelemetry
	// components into a single function.
	shutdown = func(ctx context.Context) error {
		var err error
		for _, fn := range shutdownFuncs {
			err = errors.Join(err, fn(ctx))
		}
		shutdownFuncs = nil
		return err
	}

	// Identify this application as a resource
	res, err := resource.New(ctx,
		// Use the GCP detector to pick up project ID, etc.
		resource.WithDetectors(gcp.NewDetector()),
		resource.WithTelemetrySDK(),
		resource.WithAttributes(
			semconv.ServiceName("go-task-app"),
		),
	)
	if err != nil {
		return nil, errors.Join(err, shutdown(ctx))
	}

	// Configure Context Propagation to use the default W3C traceparent format
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))

	// Use the Google Cloud Trace exporter.
	// This will automatically convert OTel spans to Cloud Trace spans.
	var opts []texporter.Option

	// Use our helper to find the Project ID
	projectID, err := getProjectID(ctx)
	if err == nil && projectID != "" {
		slog.InfoContext(ctx, "initializing cloud trace", slog.String("project_id", projectID))
		opts = append(opts, texporter.WithProjectID(projectID))
	} else {
		slog.WarnContext(ctx, "project ID not detected for trace, falling back to ADC")
	}

	traceExporter, err := texporter.New(opts...)
	if err != nil {
		return nil, errors.Join(err, shutdown(ctx))
	}

	tp := trace.NewTracerProvider(
		trace.WithBatcher(traceExporter),
		trace.WithResource(res),
	)
	shutdownFuncs = append(shutdownFuncs, tp.Shutdown)
	otel.SetTracerProvider(tp)

	return shutdown, nil
}

func setupLogging() {
	// Use json as our base logging format.
	jsonHandler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{ReplaceAttr: replacer})
	// Add span context attributes when Context is passed to logging calls.
	instrumentedHandler := handlerWithSpanContext(jsonHandler)
	// Set this handler as the global slog handler.
	slog.SetDefault(slog.New(instrumentedHandler))
}
