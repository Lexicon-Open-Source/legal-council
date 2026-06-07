package telemetry

import (
	"context"
	"errors"
	"log/slog"
	"strings"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/runtime"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploggrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/log/global"
	"go.opentelemetry.io/otel/propagation"
	sdklog "go.opentelemetry.io/otel/sdk/log"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.37.0"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

// Config holds telemetry configuration
type Config struct {
	ServiceName    string
	ServiceVersion string
	Environment    string
	OTLPEndpoint   string
	Enabled        bool
	SampleRate     float64
}

// Telemetry holds all OTel providers
type Telemetry struct {
	tracerProvider *sdktrace.TracerProvider
	meterProvider  *sdkmetric.MeterProvider
	loggerProvider *sdklog.LoggerProvider
	conn           *grpc.ClientConn
}

// New initializes OpenTelemetry with traces, metrics, and logs
func New(ctx context.Context, cfg Config, logger *slog.Logger) (*Telemetry, error) {
	if !cfg.Enabled {
		return &Telemetry{}, nil
	}

	// Normalize endpoint: gRPC expects host:port without scheme
	endpoint := cfg.OTLPEndpoint
	endpoint = strings.TrimPrefix(endpoint, "http://")
	endpoint = strings.TrimPrefix(endpoint, "https://")

	// Create gRPC connection to collector
	conn, err := grpc.NewClient(
		endpoint,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return nil, err
	}

	// Create resource with service information
	res, err := resource.Merge(
		resource.Default(),
		resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName(cfg.ServiceName),
			semconv.ServiceVersion(cfg.ServiceVersion),
			// Use deprecated "deployment.environment" for SigNoz compatibility
			// SigNoz doesn't support the new "deployment.environment.name" yet
			// See: https://github.com/SigNoz/signoz-web/issues/74
			attribute.String("deployment.environment", cfg.Environment),
		),
	)
	if err != nil {
		_ = conn.Close()
		return nil, err
	}

	// Initialize trace provider
	tracerProvider, err := initTracerProvider(ctx, conn, res, cfg.SampleRate)
	if err != nil {
		_ = conn.Close()
		return nil, err
	}

	// Initialize meter provider
	meterProvider, err := initMeterProvider(ctx, conn, res)
	if err != nil {
		_ = tracerProvider.Shutdown(ctx)
		_ = conn.Close()
		return nil, err
	}

	// Initialize logger provider
	loggerProvider, err := initLoggerProvider(ctx, conn, res)
	if err != nil {
		_ = meterProvider.Shutdown(ctx)
		_ = tracerProvider.Shutdown(ctx)
		_ = conn.Close()
		return nil, err
	}

	// Set global providers
	otel.SetTracerProvider(tracerProvider)
	otel.SetMeterProvider(meterProvider)
	global.SetLoggerProvider(loggerProvider)

	// Start Go runtime metrics collection (memory, goroutines, GC)
	if err := runtime.Start(runtime.WithMeterProvider(meterProvider)); err != nil {
		logger.Warn("Failed to start runtime metrics", "error", err)
		// Non-fatal: continue without runtime metrics
	}

	// Set global error handler to log export failures
	otel.SetErrorHandler(otel.ErrorHandlerFunc(func(err error) {
		logger.Error("OpenTelemetry export error", "error", err)
	}))

	logger.Info("OpenTelemetry providers initialized",
		"endpoint", endpoint,
		"service", cfg.ServiceName,
		"sample_rate", cfg.SampleRate,
	)

	// Set up propagation (W3C Trace Context + Baggage)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	return &Telemetry{
		tracerProvider: tracerProvider,
		meterProvider:  meterProvider,
		loggerProvider: loggerProvider,
		conn:           conn,
	}, nil
}

// Shutdown gracefully shuts down all telemetry providers
func (t *Telemetry) Shutdown(ctx context.Context) error {
	var errs []error

	if t.loggerProvider != nil {
		if err := t.loggerProvider.Shutdown(ctx); err != nil {
			errs = append(errs, err)
		}
	}

	if t.meterProvider != nil {
		if err := t.meterProvider.Shutdown(ctx); err != nil {
			errs = append(errs, err)
		}
	}

	if t.tracerProvider != nil {
		if err := t.tracerProvider.Shutdown(ctx); err != nil {
			errs = append(errs, err)
		}
	}

	if t.conn != nil {
		if err := t.conn.Close(); err != nil {
			errs = append(errs, err)
		}
	}

	return errors.Join(errs...)
}

// TracerProvider returns the tracer provider
func (t *Telemetry) TracerProvider() *sdktrace.TracerProvider {
	return t.tracerProvider
}

// MeterProvider returns the meter provider
func (t *Telemetry) MeterProvider() *sdkmetric.MeterProvider {
	return t.meterProvider
}

// LoggerProvider returns the logger provider
func (t *Telemetry) LoggerProvider() *sdklog.LoggerProvider {
	return t.loggerProvider
}

func initTracerProvider(ctx context.Context, conn *grpc.ClientConn, res *resource.Resource, sampleRate float64) (*sdktrace.TracerProvider, error) {
	exporter, err := otlptracegrpc.New(ctx, otlptracegrpc.WithGRPCConn(conn))
	if err != nil {
		return nil, err
	}

	// Configure sampler based on sample rate
	var sampler sdktrace.Sampler
	if sampleRate >= 1.0 {
		sampler = sdktrace.AlwaysSample()
	} else if sampleRate <= 0 {
		sampler = sdktrace.NeverSample()
	} else {
		sampler = sdktrace.TraceIDRatioBased(sampleRate)
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter,
			sdktrace.WithBatchTimeout(5*time.Second),
			sdktrace.WithMaxExportBatchSize(512),
			sdktrace.WithMaxQueueSize(2048),
		),
		sdktrace.WithResource(res),
		sdktrace.WithSampler(sampler),
	)

	return tp, nil
}

func initMeterProvider(ctx context.Context, conn *grpc.ClientConn, res *resource.Resource) (*sdkmetric.MeterProvider, error) {
	exporter, err := otlpmetricgrpc.New(ctx, otlpmetricgrpc.WithGRPCConn(conn))
	if err != nil {
		return nil, err
	}

	mp := sdkmetric.NewMeterProvider(
		sdkmetric.WithReader(
			sdkmetric.NewPeriodicReader(exporter,
				sdkmetric.WithInterval(15*time.Second),
			),
		),
		sdkmetric.WithResource(res),
	)

	return mp, nil
}

func initLoggerProvider(ctx context.Context, conn *grpc.ClientConn, res *resource.Resource) (*sdklog.LoggerProvider, error) {
	exporter, err := otlploggrpc.New(ctx, otlploggrpc.WithGRPCConn(conn))
	if err != nil {
		return nil, err
	}

	lp := sdklog.NewLoggerProvider(
		sdklog.WithProcessor(
			sdklog.NewBatchProcessor(exporter,
				sdklog.WithExportTimeout(5*time.Second),
				sdklog.WithExportMaxBatchSize(512),
			),
		),
		sdklog.WithResource(res),
	)

	return lp, nil
}
