package telemetry

import (
	"context"
	"log/slog"
	"os"

	"go.opentelemetry.io/contrib/bridges/otelslog"
	"go.opentelemetry.io/otel/log/global"
	"go.opentelemetry.io/otel/trace"
)

// NewLogger creates a new slog.Logger that bridges to OpenTelemetry logs
// while also outputting to stdout in JSON format
func NewLogger(serviceName string, level slog.Level, otelEnabled bool) *slog.Logger {
	// Base JSON handler for stdout
	jsonHandler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level:     level,
		AddSource: true,
	})

	if !otelEnabled {
		return slog.New(jsonHandler)
	}

	// Create OTel slog handler that sends logs to the LoggerProvider
	// Must explicitly pass the global LoggerProvider - otelslog doesn't auto-detect it
	otelHandler := otelslog.NewHandler(serviceName,
		otelslog.WithLoggerProvider(global.GetLoggerProvider()),
	)

	// Use a multi-handler that writes to both stdout and OTel
	multiHandler := &multiHandler{
		handlers: []slog.Handler{jsonHandler, otelHandler},
	}

	return slog.New(multiHandler)
}

// multiHandler writes to multiple slog handlers
type multiHandler struct {
	handlers []slog.Handler
}

func (m *multiHandler) Enabled(ctx context.Context, level slog.Level) bool {
	for _, h := range m.handlers {
		if h.Enabled(ctx, level) {
			return true
		}
	}
	return false
}

func (m *multiHandler) Handle(ctx context.Context, r slog.Record) error {
	for _, h := range m.handlers {
		if h.Enabled(ctx, r.Level) {
			if err := h.Handle(ctx, r); err != nil {
				return err
			}
		}
	}
	return nil
}

func (m *multiHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	handlers := make([]slog.Handler, len(m.handlers))
	for i, h := range m.handlers {
		handlers[i] = h.WithAttrs(attrs)
	}
	return &multiHandler{handlers: handlers}
}

func (m *multiHandler) WithGroup(name string) slog.Handler {
	handlers := make([]slog.Handler, len(m.handlers))
	for i, h := range m.handlers {
		handlers[i] = h.WithGroup(name)
	}
	return &multiHandler{handlers: handlers}
}

// LoggerWithTrace returns a logger with trace context attributes
func LoggerWithTrace(logger *slog.Logger, ctx context.Context) *slog.Logger {
	span := trace.SpanFromContext(ctx)
	if !span.SpanContext().IsValid() {
		return logger
	}

	return logger.With(
		slog.String("trace_id", span.SpanContext().TraceID().String()),
		slog.String("span_id", span.SpanContext().SpanID().String()),
	)
}

// ParseLogLevel parses a string log level to slog.Level
func ParseLogLevel(level string) slog.Level {
	switch level {
	case "debug":
		return slog.LevelDebug
	case "info":
		return slog.LevelInfo
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
