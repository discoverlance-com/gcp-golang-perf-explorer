package main

import (
	"context"
	"errors"
	"log/slog"
	"os"

	"github.com/joho/godotenv"
)

func main() {
	// Load .env file if it exists
	_ = godotenv.Load()

	ctx := context.Background()

	// Setup logging
	setupLogging()

	// Setup metrics, tracing, and context propagation
	shutdown, err := setupOpenTelemetry(ctx)
	if err != nil {
		slog.ErrorContext(ctx, "error setting up OpenTelemetry", slog.Any("error", err))
		os.Exit(1)
	}

	// Run the http server, and shutdown and flush telemetry after it exits.
	slog.InfoContext(ctx, "server starting...")
	if err = errors.Join(runServer(), shutdown(ctx)); err != nil {
		slog.ErrorContext(ctx, "server exited with error", slog.Any("error", err))
		os.Exit(1)
	}
}
