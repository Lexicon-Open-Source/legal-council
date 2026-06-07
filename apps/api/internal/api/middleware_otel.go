package api

import (
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/lexiconindonesia/lexicon-backend/internal/telemetry"
	"github.com/riandyrn/otelchi"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
	written    bool
}

func newResponseWriter(w http.ResponseWriter) *responseWriter {
	return &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
}

func (rw *responseWriter) WriteHeader(code int) {
	if !rw.written {
		rw.statusCode = code
		rw.written = true
	}
	rw.ResponseWriter.WriteHeader(code)
}

func (rw *responseWriter) Write(b []byte) (int, error) {
	if !rw.written {
		rw.written = true
	}
	return rw.ResponseWriter.Write(b)
}

// Flush implements http.Flusher to support SSE streaming.
// Without this, middleware that wraps ResponseWriter breaks streaming endpoints.
func (rw *responseWriter) Flush() {
	if flusher, ok := rw.ResponseWriter.(http.Flusher); ok {
		flusher.Flush()
	}
}

// otelChiMiddleware creates Chi-specific OpenTelemetry middleware with best practices
func otelChiMiddleware(serviceName string, router chi.Routes) func(http.Handler) http.Handler {
	return otelchi.Middleware(serviceName,
		// Use route patterns as span names (e.g., "/users/{id}" instead of "/users/123")
		otelchi.WithChiRoutes(router),
		// Add HTTP method to span name (e.g., "GET /users/{id}")
		otelchi.WithRequestMethodInSpanName(true),
		// Exclude health check endpoints from tracing (reduces noise)
		otelchi.WithFilter(func(r *http.Request) bool {
			// Return false to exclude from tracing
			path := r.URL.Path
			return !strings.HasPrefix(path, "/health") && !strings.HasPrefix(path, "/ready")
		}),
		// Add trace ID to response headers for debugging
		otelchi.WithTraceResponseHeaders(otelchi.TraceHeaderConfig{
			TraceIDHeader:      "X-Trace-Id",
			TraceSampledHeader: "X-Trace-Sampled",
		}),
	)
}

// isHealthCheckPath returns true if the path is a health check endpoint
// that should be excluded from observability (metrics, logging)
func isHealthCheckPath(path string) bool {
	return strings.HasPrefix(path, "/health") || strings.HasPrefix(path, "/ready")
}

// metricsMiddleware records HTTP request metrics
func metricsMiddleware(metrics *telemetry.Metrics) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if metrics == nil {
				next.ServeHTTP(w, r)
				return
			}

			// Exclude health check endpoints from metrics to reduce dashboard noise
			if isHealthCheckPath(r.URL.Path) {
				next.ServeHTTP(w, r)
				return
			}

			ctx := r.Context()
			start := time.Now()

			// Track in-flight requests
			metrics.RequestsInFlight.Add(ctx, 1)
			defer metrics.RequestsInFlight.Add(ctx, -1)

			// Wrap response writer to capture status code
			rw := newResponseWriter(w)

			next.ServeHTTP(rw, r)

			// Record request metrics
			duration := time.Since(start)
			metrics.RecordHTTPRequest(ctx, r.Method, r.URL.Path, rw.statusCode, duration)
		})
	}
}

// traceAttributesMiddleware adds custom attributes to the current span
func traceAttributesMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		span := trace.SpanFromContext(ctx)

		// Add request ID as span attribute
		if requestID, ok := ctx.Value(requestIDKey).(string); ok {
			span.SetAttributes(attribute.String("request.id", requestID))
		}

		// Add user agent
		if ua := r.UserAgent(); ua != "" {
			span.SetAttributes(attribute.String("http.user_agent", ua))
		}

		// Add client IP
		if ip := getClientIP(r); ip != "" {
			span.SetAttributes(attribute.String("http.client_ip", ip))
		}

		next.ServeHTTP(w, r)
	})
}

// getClientIP extracts the client IP from the request
func getClientIP(r *http.Request) string {
	// Check X-Forwarded-For header first
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		return xff
	}
	// Check X-Real-IP header
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return xri
	}
	// Fall back to RemoteAddr
	return r.RemoteAddr
}
