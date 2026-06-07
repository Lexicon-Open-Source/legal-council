package api

import (
	"context"
	"log/slog"
	"net/http"
	"runtime/debug"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/lexiconindonesia/lexicon-backend/internal/telemetry"
)

// sanitizeLogValue removes control characters that could be used for log injection attacks.
// This prevents attackers from forging log entries via newline injection or manipulating
// log viewers with control characters.
func sanitizeLogValue(s string) string {
	return strings.Map(func(r rune) rune {
		// Remove newlines, carriage returns, and other control characters
		if r == '\n' || r == '\r' || r < 32 {
			return -1
		}
		return r
	}, s)
}

type contextKey string

const requestIDKey contextKey = "requestID"

// requestIDMiddleware adds a unique request ID to each request
func requestIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := r.Header.Get("X-Request-ID")
		if requestID == "" {
			requestID = uuid.New().String()
		}

		ctx := context.WithValue(r.Context(), requestIDKey, requestID)
		w.Header().Set("X-Request-ID", requestID)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// loggingMiddleware logs HTTP requests with trace context
func loggingMiddleware(logger *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Exclude health check endpoints from logging to reduce noise
			if isHealthCheckPath(r.URL.Path) {
				next.ServeHTTP(w, r)
				return
			}

			start := time.Now()
			ctx := r.Context()

			requestID, _ := ctx.Value(requestIDKey).(string)

			// Wrap response writer to capture status code
			wrapped := newResponseWriter(w)

			// Get logger with trace context
			log := telemetry.LoggerWithTrace(logger, ctx)

			// Serve the request
			next.ServeHTTP(wrapped, r)

			// Calculate duration (direct calculation, no intermediate variable)
			durationMs := time.Since(start).Milliseconds()

			// Sanitize path to prevent log injection attacks (OWASP A03:2021)
			safePath := sanitizeLogValue(r.URL.Path)

			// Build attributes with pre-allocated capacity to avoid reallocations
			// Query params intentionally omitted to prevent sensitive data exposure
			attrs := []any{
				"method", r.Method,
				"path", safePath,
				"status", wrapped.statusCode,
				"duration_ms", durationMs,
				"request_id", requestID,
			}

			// Log at appropriate level based on status code
			// Use static message - structured attrs carry all the data for SigNoz
			switch {
			case wrapped.statusCode >= 500:
				log.Error("http request", attrs...)
			case wrapped.statusCode >= 400:
				log.Warn("http request", attrs...)
			default:
				log.Info("http request", attrs...)
			}
		})
	}
}

// recoveryMiddleware recovers from panics and logs the error with trace context
func recoveryMiddleware(logger *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if err := recover(); err != nil {
					ctx := r.Context()
					requestID, _ := ctx.Value(requestIDKey).(string)

					log := telemetry.LoggerWithTrace(logger, ctx)
					log.Error("Panic recovered",
						"error", err,
						"stack", string(debug.Stack()),
						"request_id", requestID,
					)

					http.Error(w, "Internal Server Error", http.StatusInternalServerError)
				}
			}()

			next.ServeHTTP(w, r)
		})
	}
}
