package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"
	"github.com/lexiconindonesia/lexicon-backend/internal/api"
	"github.com/lexiconindonesia/lexicon-backend/internal/config"
	"github.com/lexiconindonesia/lexicon-backend/internal/telemetry"
)

func main() {
	// Load .env if present (native dev). Does not override vars already set
	// in the environment (e.g. docker-compose), so those still win.
	_ = godotenv.Load()

	cfg, err := config.Load()
	if err != nil {
		slog.Error("Failed to load configuration", "error", err)
		os.Exit(1)
	}

	// Initialize basic logger first (before OTel)
	logLevel := telemetry.ParseLogLevel(cfg.LogLevel)
	basicLogger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level:     logLevel,
		AddSource: true,
	}))

	// Initialize OpenTelemetry with basic logger
	ctx := context.Background()
	otel, err := telemetry.New(ctx, telemetry.Config{
		ServiceName:    cfg.AppName,
		ServiceVersion: cfg.ServiceVersion,
		Environment:    cfg.Environment,
		OTLPEndpoint:   cfg.OTelEndpoint,
		Enabled:        cfg.OTelEnabled,
		SampleRate:     cfg.OTelSampleRate,
	}, basicLogger)
	if err != nil {
		basicLogger.Error("Failed to initialize telemetry", "error", err)
		os.Exit(1)
	}
	defer func() {
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := otel.Shutdown(shutdownCtx); err != nil {
			slog.Error("Failed to shutdown telemetry", "error", err)
		}
	}()

	// Setup OTel-integrated logger (replaces basic logger)
	logger := telemetry.NewLogger(cfg.AppName, logLevel, cfg.OTelEnabled)
	slog.SetDefault(logger)

	// Initialize metrics
	var metrics *telemetry.Metrics
	if cfg.OTelEnabled {
		metrics, err = telemetry.NewMetrics()
		if err != nil {
			logger.Error("Failed to initialize metrics", "error", err)
			os.Exit(1)
		}
	}

	server, err := api.NewServer(cfg, logger, metrics)
	if err != nil {
		logger.Error("Failed to create server", "error", err)
		os.Exit(1)
	}
	defer server.Close()

	httpServer := &http.Server{
		Addr:              fmt.Sprintf(":%d", cfg.Port),
		Handler:           server.Router(),
		ReadTimeout:       90 * time.Second, // Must exceed LLM timeout
		ReadHeaderTimeout: 10 * time.Second, // Slowloris attack protection
		WriteTimeout:      cfg.HTTPWriteTimeout,
		IdleTimeout:       120 * time.Second,
	}

	go func() {
		logger.Info("Starting server", "port", cfg.Port, "env", cfg.Environment)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("Server error", "error", err)
			os.Exit(1)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		logger.Error("Server forced to shutdown", "error", err)
	}
	logger.Info("Server stopped")
}
