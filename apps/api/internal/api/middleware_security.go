package api

import (
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/httprate"
	httprateredis "github.com/go-chi/httprate-redis"
	"github.com/lexiconindonesia/lexicon-backend/internal/i18n"
	"github.com/redis/go-redis/v9"
)

const (
	rateLimitRequestsPerMinute               = 100
	egressRateLimitRequestsPerMinute         = 30
	appKeyFallbackRateLimitRequestsPerMinute = 30
	adminRateLimitRequestsPerMinute          = 120
	maxRequestBodySize                       = 1 << 20 // 1MB
)

// turnstileVerificationTierKey is the context key for the verification tier
// set by the Turnstile middleware and read by the tiered rate limiter.
type turnstileVerificationTierKey struct{}

// Verification tier values set in request context by the Turnstile middleware.
const (
	verificationTierTurnstile = "turnstile"
	verificationTierSession   = "session"
	verificationTierAppKey    = "appkey"
)

// securityHeadersMiddleware adds essential security headers.
// No CSP needed for JSON API (CSP protects HTML rendering).
func securityHeadersMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")
		w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
		next.ServeHTTP(w, r)
	})
}

// rateLimitMiddleware limits requests to 100/min per IP using Redis.
// Uses fail-closed behavior (FallbackDisabled) - rejects requests if Redis unavailable.
// Panics on initialization failure to fail fast - a broken rate limiter should prevent server startup
// rather than allowing it to start and reject all requests with 503 errors.
func rateLimitMiddleware(redisClient *redis.Client, logger *slog.Logger) func(http.Handler) http.Handler {
	counter, err := httprateredis.NewRedisLimitCounter(&httprateredis.Config{
		Client:           redisClient,
		PrefixKey:        "ratelimit",
		FallbackDisabled: true, // Fail closed - reject requests if Redis unavailable
		OnError: func(err error) {
			logger.Error("rate limit redis error", "error", err)
		},
	})
	if err != nil {
		logger.Error("failed to create Redis rate limit counter", "error", err)
		panic(fmt.Sprintf("failed to create Redis rate limit counter: %v", err))
	}

	return httprate.Limit(
		rateLimitRequestsPerMinute,
		time.Minute,
		httprate.WithKeyFuncs(httprate.KeyByRealIP),
		httprate.WithLimitCounter(counter),
		httprate.WithLimitHandler(jsonRateLimitHandler),
	)
}

// RateLimitConfig holds configuration for rate limiting.
type RateLimitConfig struct {
	RequestsPerMinute int
	KeyPrefix         string
}

// rateLimitMiddlewareWithConfig creates a rate limiter with custom configuration.
// Uses fail-closed behavior (FallbackDisabled) - rejects requests if Redis unavailable.
// Panics on initialization failure to fail fast.
//
// 429 responses are emitted as the standard JSON Error envelope so callers
// (including admin clients) get a consistent shape across the rate-limit,
// auth, and validation paths.
func rateLimitMiddlewareWithConfig(redisClient *redis.Client, logger *slog.Logger, config RateLimitConfig) func(http.Handler) http.Handler {
	counter, err := httprateredis.NewRedisLimitCounter(&httprateredis.Config{
		Client:           redisClient,
		PrefixKey:        config.KeyPrefix,
		FallbackDisabled: true, // Fail closed - reject requests if Redis unavailable
		OnError: func(err error) {
			logger.Error("rate limit redis error", "error", err, "prefix", config.KeyPrefix)
		},
	})
	if err != nil {
		logger.Error("failed to create Redis rate limit counter", "error", err, "prefix", config.KeyPrefix)
		panic(fmt.Sprintf("failed to create Redis rate limit counter for %s: %v", config.KeyPrefix, err))
	}

	return httprate.Limit(
		config.RequestsPerMinute,
		time.Minute,
		httprate.WithKeyFuncs(httprate.KeyByRealIP),
		httprate.WithLimitCounter(counter),
		httprate.WithLimitHandler(jsonRateLimitHandler),
	)
}

// jsonRateLimitHandler emits the standard {error, status_code} envelope on 429.
// Replaces httprate's default plain-text response so admin clients (and any
// other JSON-only consumer) get a parseable body matching every other error.
//
// httprate pre-populates `X-RateLimit-Reset` with the seconds remaining in
// the current window; we mirror it into the standard `Retry-After` header
// so callers (browsers, the admin dashboard, generic HTTP clients) can back
// off without having to know about httprate-specific headers. Falls back to
// the window duration (60s) when the upstream header is missing, since all
// rate limiters in this service use a 1-minute window.
func jsonRateLimitHandler(w http.ResponseWriter, r *http.Request) {
	retryAfter := w.Header().Get("X-RateLimit-Reset")
	if retryAfter == "" {
		retryAfter = "60"
	}
	w.Header().Set("Retry-After", retryAfter)
	writeError(w, i18n.T(r.Context(), i18n.MsgErrorRateLimitExceeded), http.StatusTooManyRequests)
}

// tieredRateLimitMiddleware applies different rate limits based on the Turnstile
// verification tier stored in context by the Turnstile middleware.
//   - Tier "turnstile" or "session": 100 req/min (standard)
//   - Tier "appkey": 30 req/min (strict, separate Redis counter)
//   - No tier set: 100 req/min (default — shouldn't happen, Turnstile middleware runs first)
func tieredRateLimitMiddleware(redisClient *redis.Client, logger *slog.Logger) func(http.Handler) http.Handler {
	standardLimiter := rateLimitMiddleware(redisClient, logger)
	appKeyLimiter := rateLimitMiddlewareWithConfig(redisClient, logger, RateLimitConfig{
		RequestsPerMinute: appKeyFallbackRateLimitRequestsPerMinute,
		KeyPrefix:         "ratelimit:appkey",
	})

	return func(next http.Handler) http.Handler {
		// Pre-wrap handlers at registration time (not per-request).
		standardHandler := standardLimiter(next)
		appKeyHandler := appKeyLimiter(next)

		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			tier, _ := r.Context().Value(turnstileVerificationTierKey{}).(string)
			if tier == verificationTierAppKey {
				appKeyHandler.ServeHTTP(w, r)
			} else {
				standardHandler.ServeHTTP(w, r)
			}
		})
	}
}

// bodySizeLimitMiddleware limits request bodies to 1MB.
func bodySizeLimitMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		r.Body = http.MaxBytesReader(w, r.Body, maxRequestBodySize)
		next.ServeHTTP(w, r)
	})
}

// uploadBodySizeLimitMiddleware returns a middleware that limits request bodies to the given size.
// Used for file upload routes that need a higher limit than the default 1MB.
func uploadBodySizeLimitMiddleware(maxSize int64) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			r.Body = http.MaxBytesReader(w, r.Body, maxSize)
			next.ServeHTTP(w, r)
		})
	}
}
