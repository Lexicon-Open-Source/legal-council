package telemetry

import (
	"context"
	"strings"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
)

const meterName = "lexicon-backend"

// Metrics holds all application metrics
type Metrics struct {
	// HTTP metrics
	RequestsTotal    metric.Int64Counter
	RequestDuration  metric.Float64Histogram
	RequestsInFlight metric.Int64UpDownCounter

	// Database metrics
	DBQueryDuration     metric.Float64Histogram
	DBQueryErrors       metric.Int64Counter
	DBConnectionsActive metric.Int64UpDownCounter

	// Redis metrics
	RedisOperationDuration metric.Float64Histogram
	RedisCacheHits         metric.Int64Counter
	RedisCacheMisses       metric.Int64Counter

	// Business metrics
	SearchRequests  metric.Int64Counter
	ChatbotRequests metric.Int64Counter
	LLMRequests     metric.Int64Counter
	LLMLatency      metric.Float64Histogram
}

// NewMetrics creates and registers all application metrics
func NewMetrics() (*Metrics, error) {
	meter := otel.Meter(meterName)

	m := &Metrics{}
	var err error

	// HTTP metrics
	m.RequestsTotal, err = meter.Int64Counter(
		"http.server.requests_total",
		metric.WithDescription("Total number of HTTP requests"),
		metric.WithUnit("{request}"),
	)
	if err != nil {
		return nil, err
	}

	m.RequestDuration, err = meter.Float64Histogram(
		"http.server.request_duration_seconds",
		metric.WithDescription("HTTP request duration in seconds"),
		metric.WithUnit("s"),
		metric.WithExplicitBucketBoundaries(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10),
	)
	if err != nil {
		return nil, err
	}

	m.RequestsInFlight, err = meter.Int64UpDownCounter(
		"http.server.requests_in_flight",
		metric.WithDescription("Number of HTTP requests currently being processed"),
		metric.WithUnit("{request}"),
	)
	if err != nil {
		return nil, err
	}

	// Database metrics
	m.DBQueryDuration, err = meter.Float64Histogram(
		"db.client.operation.duration",
		metric.WithDescription("Duration of database operations"),
		metric.WithUnit("s"),
		metric.WithExplicitBucketBoundaries(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1),
	)
	if err != nil {
		return nil, err
	}

	m.DBQueryErrors, err = meter.Int64Counter(
		"db.client.operation.errors_total",
		metric.WithDescription("Total number of database operation errors"),
		metric.WithUnit("{error}"),
	)
	if err != nil {
		return nil, err
	}

	m.DBConnectionsActive, err = meter.Int64UpDownCounter(
		"db.client.connections.active",
		metric.WithDescription("Number of active database connections"),
		metric.WithUnit("{connection}"),
	)
	if err != nil {
		return nil, err
	}

	// Redis metrics
	m.RedisOperationDuration, err = meter.Float64Histogram(
		"redis.client.operation.duration",
		metric.WithDescription("Duration of Redis operations"),
		metric.WithUnit("s"),
		metric.WithExplicitBucketBoundaries(0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1),
	)
	if err != nil {
		return nil, err
	}

	m.RedisCacheHits, err = meter.Int64Counter(
		"redis.client.cache_hits_total",
		metric.WithDescription("Total number of Redis cache hits"),
		metric.WithUnit("{hit}"),
	)
	if err != nil {
		return nil, err
	}

	m.RedisCacheMisses, err = meter.Int64Counter(
		"redis.client.cache_misses_total",
		metric.WithDescription("Total number of Redis cache misses"),
		metric.WithUnit("{miss}"),
	)
	if err != nil {
		return nil, err
	}

	// Business metrics
	m.SearchRequests, err = meter.Int64Counter(
		"business.search_requests_total",
		metric.WithDescription("Total number of search requests"),
		metric.WithUnit("{request}"),
	)
	if err != nil {
		return nil, err
	}

	m.ChatbotRequests, err = meter.Int64Counter(
		"business.chatbot_requests_total",
		metric.WithDescription("Total number of chatbot requests"),
		metric.WithUnit("{request}"),
	)
	if err != nil {
		return nil, err
	}

	m.LLMRequests, err = meter.Int64Counter(
		"business.llm_requests_total",
		metric.WithDescription("Total number of LLM service requests"),
		metric.WithUnit("{request}"),
	)
	if err != nil {
		return nil, err
	}

	m.LLMLatency, err = meter.Float64Histogram(
		"business.llm_latency_seconds",
		metric.WithDescription("LLM service request latency in seconds"),
		metric.WithUnit("s"),
		metric.WithExplicitBucketBoundaries(0.5, 1, 2.5, 5, 10, 15, 30, 60),
	)
	if err != nil {
		return nil, err
	}

	return m, nil
}

// RecordHTTPRequest records HTTP request metrics
// Uses OpenTelemetry semantic conventions v1.21+ attribute names
func (m *Metrics) RecordHTTPRequest(ctx context.Context, method, path string, statusCode int, duration time.Duration) {
	attrs := []attribute.KeyValue{
		attribute.String("http.request.method", method),
		attribute.String("http.route", path),
		attribute.Int("http.response.status_code", statusCode),
	}

	m.RequestsTotal.Add(ctx, 1, metric.WithAttributes(attrs...))
	m.RequestDuration.Record(ctx, duration.Seconds(), metric.WithAttributes(attrs...))
}

// RecordDBQuery records database query metrics
// Uses OpenTelemetry semantic conventions v1.21+ attribute names
func (m *Metrics) RecordDBQuery(ctx context.Context, operation string, duration time.Duration, err error) {
	attrs := []attribute.KeyValue{
		attribute.String("db.operation.name", operation),
	}

	m.DBQueryDuration.Record(ctx, duration.Seconds(), metric.WithAttributes(attrs...))

	if err != nil {
		errorAttrs := append(attrs, attribute.String("error.type", errorType(err)))
		m.DBQueryErrors.Add(ctx, 1, metric.WithAttributes(errorAttrs...))
	}
}

// RecordDBConnectionState records database connection pool state
// state should be one of: "idle", "active", "waiting"
func (m *Metrics) RecordDBConnectionState(ctx context.Context, state string, delta int64) {
	attrs := []attribute.KeyValue{
		attribute.String("db.client.connection.state", state),
	}
	m.DBConnectionsActive.Add(ctx, delta, metric.WithAttributes(attrs...))
}

// errorType extracts a short error type from an error
func errorType(err error) string {
	if err == nil {
		return ""
	}
	// Use the error type name, or fallback to a generic category
	switch {
	case isTimeout(err):
		return "timeout"
	case isConnectionError(err):
		return "connection"
	default:
		return "query"
	}
}

// isTimeout checks if the error is a timeout error
func isTimeout(err error) bool {
	if err == nil {
		return false
	}
	errStr := strings.ToLower(err.Error())
	return strings.Contains(errStr, "timeout") || strings.Contains(errStr, "deadline exceeded")
}

// isConnectionError checks if the error is a connection error
func isConnectionError(err error) bool {
	if err == nil {
		return false
	}
	errStr := strings.ToLower(err.Error())
	return strings.Contains(errStr, "connection") || strings.Contains(errStr, "refused") || strings.Contains(errStr, "reset")
}

// RecordRedisOperation records Redis operation metrics
func (m *Metrics) RecordRedisOperation(ctx context.Context, operation string, duration time.Duration, hit bool) {
	attrs := []attribute.KeyValue{
		attribute.String("redis.operation", operation),
	}

	m.RedisOperationDuration.Record(ctx, duration.Seconds(), metric.WithAttributes(attrs...))

	if hit {
		m.RedisCacheHits.Add(ctx, 1, metric.WithAttributes(attrs...))
	} else {
		m.RedisCacheMisses.Add(ctx, 1, metric.WithAttributes(attrs...))
	}
}

// RecordSearch records search request metrics
func (m *Metrics) RecordSearch(ctx context.Context, searchType string) {
	attrs := []attribute.KeyValue{
		attribute.String("search.type", searchType),
	}
	m.SearchRequests.Add(ctx, 1, metric.WithAttributes(attrs...))
}

// RecordChatbot records chatbot request metrics
func (m *Metrics) RecordChatbot(ctx context.Context, success bool) {
	attrs := []attribute.KeyValue{
		attribute.Bool("chatbot.success", success),
	}
	m.ChatbotRequests.Add(ctx, 1, metric.WithAttributes(attrs...))
}

// RecordLLMRequest records LLM service request metrics
func (m *Metrics) RecordLLMRequest(ctx context.Context, duration time.Duration, success bool) {
	attrs := []attribute.KeyValue{
		attribute.Bool("llm.success", success),
	}
	m.LLMRequests.Add(ctx, 1, metric.WithAttributes(attrs...))
	m.LLMLatency.Record(ctx, duration.Seconds(), metric.WithAttributes(attrs...))
}
