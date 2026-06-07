package api

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"github.com/amirsalarsafaei/sqlc-pgx-monitoring/dbtracer"
	"github.com/amirsalarsafaei/sqlc-pgx-monitoring/poolstatus"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/lexiconindonesia/lexicon-backend/internal/config"
	"github.com/lexiconindonesia/lexicon-backend/internal/telemetry"
	"github.com/redis/go-redis/extra/redisotel/v9"
	"github.com/redis/go-redis/v9"
	"go.opentelemetry.io/otel"
)

// Server holds the dependencies for the council proxy service. The council
// HTTP handlers are a pure reverse proxy to the external LLM service; the
// database and Redis pools are retained only for the readiness probe.
type Server struct {
	cfg     *config.Config
	db      *pgxpool.Pool
	redis   *redis.Client
	llmHTTP *http.Client // Secure HTTP client for LLM service (council endpoints)
	router  chi.Router
	logger  *slog.Logger
	metrics *telemetry.Metrics
}

func NewServer(cfg *config.Config, logger *slog.Logger, metrics *telemetry.Metrics) (*Server, error) {
	// Parse database connection string
	poolConfig, err := pgxpool.ParseConfig(cfg.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database URL: %w", err)
	}

	// Configure connection pool based on environment
	poolConfig.MaxConns = int32(cfg.DatabaseMaxConns)     // 25
	poolConfig.MinConns = int32(cfg.DatabaseMaxConns / 5) // 5 - maintain baseline
	poolConfig.MaxConnIdleTime = 15 * time.Minute         // Faster cleanup
	poolConfig.MaxConnLifetime = 1 * time.Hour            // Connection refresh
	poolConfig.HealthCheckPeriod = 1 * time.Minute        // Detect stale connections

	// Add OpenTelemetry tracing and metrics to pgx if enabled
	if cfg.OTelEnabled {
		tracer, err := dbtracer.NewDBTracer(
			"lexicon",
			dbtracer.WithLogger(logger),
			dbtracer.WithMeterProvider(otel.GetMeterProvider()),
			dbtracer.WithTraceProvider(otel.GetTracerProvider()),
			dbtracer.WithIncludeSQLText(true),
			dbtracer.WithIncludeSpanNameSuffix(true),
		)
		if err != nil {
			return nil, fmt.Errorf("failed to create db tracer: %w", err)
		}
		poolConfig.ConnConfig.Tracer = tracer
	}

	// Initialize database connection pool
	dbPool, err := pgxpool.NewWithConfig(context.Background(), poolConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create connection pool: %w", err)
	}

	// Register pool status monitoring for connection pool metrics
	if cfg.OTelEnabled {
		if err := poolstatus.Register(dbPool,
			poolstatus.WithMeterProvider(otel.GetMeterProvider()),
		); err != nil {
			logger.Warn("Failed to register pool status monitoring", "error", err)
		}
	}

	// Test database connection
	if err := dbPool.Ping(context.Background()); err != nil {
		dbPool.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	logger.Info("Connected to database", "max_conns", poolConfig.MaxConns, "min_conns", poolConfig.MinConns)

	// Initialize Redis client
	opt, err := redis.ParseURL(cfg.RedisURL)
	if err != nil {
		dbPool.Close()
		return nil, fmt.Errorf("failed to parse redis URL: %w", err)
	}

	redisClient := redis.NewClient(opt)

	// Add OpenTelemetry tracing to Redis if enabled
	if cfg.OTelEnabled {
		if err := redisotel.InstrumentTracing(redisClient); err != nil {
			logger.Warn("Failed to instrument Redis tracing", "error", err)
		}
		if err := redisotel.InstrumentMetrics(redisClient); err != nil {
			logger.Warn("Failed to instrument Redis metrics", "error", err)
		}
	}

	// Test Redis connection
	if err := redisClient.Ping(context.Background()).Err(); err != nil {
		dbPool.Close()
		_ = redisClient.Close()
		return nil, fmt.Errorf("failed to ping redis: %w", err)
	}

	logger.Info("Connected to Redis")

	// Initialize secure HTTP client for LLM service (council endpoints) with DNS rebinding protection
	llmHTTP, err := newLLMHTTPClient(cfg)
	if err != nil {
		dbPool.Close()
		_ = redisClient.Close()
		return nil, fmt.Errorf("initialize LLM HTTP client: %w", err)
	}

	s := &Server{
		cfg:     cfg,
		db:      dbPool,
		redis:   redisClient,
		llmHTTP: llmHTTP,
		logger:  logger,
		metrics: metrics,
	}

	// Setup routes
	s.router = s.setupRoutes()

	return s, nil
}

func (s *Server) Router() chi.Router {
	return s.router
}

func (s *Server) Close() {
	if s.db != nil {
		s.db.Close()
		slog.Info("Database connection closed")
	}
	if s.redis != nil {
		_ = s.redis.Close()
		slog.Info("Redis connection closed")
	}
}
