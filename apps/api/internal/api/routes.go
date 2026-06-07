package api

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/lexiconindonesia/lexicon-backend/internal/config"
	"github.com/lexiconindonesia/lexicon-backend/internal/i18n"
)

// getTurnstileAllowedHostnames returns environment-aware hostnames for Turnstile verification.
// Cloudflare returns the hostname where the widget was rendered; we verify it matches.
// Development skips hostname verification entirely (returns empty list).
func getTurnstileAllowedHostnames(environment string) []string {
	if environment == "development" {
		return nil // Skip hostname verification in development
	}

	return []string{
		"justicia.id",
		"lexicon.id",
	}
}

// getAllowedOrigins returns environment-aware CORS origins.
// Production uses HTTPS-only, development allows HTTP and localhost.
func getAllowedOrigins(cfg *config.Config) []string {
	// Always allow HTTPS origins
	origins := []string{
		"https://*.lexicon.id",
		"https://lexicon.id",
		"https://*.justicia.id",
		"https://justicia.id",
	}

	// Only allow HTTP origins in development
	if cfg.Environment == "development" {
		origins = append(origins,
			"http://*.lexicon.id",
			"http://lexicon.id",
			"http://*.justicia.id",
			"http://justicia.id",
			"http://localhost:3000",
			"http://localhost:3001",
			"http://localhost:3002",
			"http://localhost:3003",
			"http://localhost:3004",
			"http://localhost:3005",
			"http://localhost:3006",
			"http://localhost:3007",
			"http://localhost:3008",
			"http://localhost:3009",
			"http://localhost:3010",
		)
	}

	// Only allow HTTP origins in staging
	if cfg.Environment == "staging" {
		origins = append(origins,
			"http://*.lexicon.id",
			"http://lexicon.id",
			"http://*.justicia.id",
			"http://justicia.id",
			"http://localhost:3000",
			"http://localhost:3001",
			"http://localhost:3002",
			"http://localhost:3003",
			"http://localhost:3004",
			"http://localhost:3005",
			"http://localhost:3006",
			"http://localhost:3007",
			"http://localhost:3008",
			"http://localhost:3009",
			"http://localhost:3010",
		)
	}

	return origins
}

func (s *Server) setupRoutes() chi.Router {
	r := chi.NewRouter()

	// Middleware stack (order matters)
	// 1. Request ID - must be first to generate ID for all subsequent middleware
	r.Use(requestIDMiddleware)

	// 2. RealIP - extracts the real client IP from X-Forwarded-For or X-Real-IP headers
	// MUST be early in the chain so all subsequent middleware (rate limiting, bot detection)
	// see the correct client IP in r.RemoteAddr.
	r.Use(middleware.RealIP)

	// 3. OpenTelemetry HTTP tracing - must be early to capture ALL requests including rate-limited ones
	if s.cfg.OTelEnabled {
		r.Use(otelChiMiddleware(s.cfg.AppName, r))
		r.Use(traceAttributesMiddleware)
	}

	// 4. Metrics collection - capture metrics for all requests
	r.Use(metricsMiddleware(s.metrics))

	// 5. Logging with trace context
	r.Use(loggingMiddleware(s.logger))

	// 6. Panic recovery with trace context
	r.Use(recoveryMiddleware(s.logger))

	// 7. Security headers - applied to ALL responses including health checks
	r.Use(securityHeadersMiddleware)

	// 8. i18n - parse Accept-Language header and store localizer in context.
	r.Use(i18n.LanguageMiddleware)

	// CORS - environment-aware origins (HTTPS-only in production)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   getAllowedOrigins(s.cfg),
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Accept-Language", "Authorization", "Content-Type", "X-Lexicon-Api-Key", "X-Turnstile-Token", "X-Turnstile-Session", "X-Turnstile-App-Key"},
		ExposedHeaders:   []string{"Link", "X-Turnstile-Session"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// Health check endpoints - BEFORE rate limiting and bot detection
	// Kubernetes probes must not be rate limited or blocked by bot detection
	r.Get("/health", s.handleHealth)
	r.Get("/ready", s.handleReady)

	// Bot detection configuration - applied to API routes only
	botConfig := BotDetectionConfig{
		Enabled:                    s.cfg.BotDetectionEnabled,
		BlockBots:                  s.cfg.BotDetectionBlockBots,
		SearchDetailRatioThreshold: s.cfg.BotDetectionRatioThreshold,
		RequestsPerMinuteThreshold: s.cfg.BotDetectionRateThreshold,
		WindowDuration:             s.cfg.BotDetectionWindowDuration,
		WhitelistGoodBots:          s.cfg.BotDetectionWhitelistGoodBots,
	}

	// Turnstile configuration - server-side Cloudflare challenge verification.
	// Only protects specific user-facing endpoints that render the Turnstile widget.
	// Tier 1: Cloudflare Turnstile token (issues session token on success)
	// Tier 2: HMAC session token (stateless, 5-min TTL)
	// Tier 3: App API key (stricter rate limit)
	var sessionSecret []byte
	if s.cfg.TurnstileSessionSecret != "" {
		sessionSecret = decodeHexKey(s.cfg.TurnstileSessionSecret)
	}
	turnstileConfig := TurnstileConfig{
		Enabled:          s.cfg.TurnstileEnabled,
		SecretKey:        s.cfg.TurnstileSecretKey,
		AllowedHostnames: getTurnstileAllowedHostnames(s.cfg.Environment),
		SessionSecret:    sessionSecret,
		SessionTTL:       5 * time.Minute,
		SessionGrace:     30 * time.Second,
		AppAPIKey:        s.cfg.TurnstileAppAPIKey,
		ProtectedRoutes: []turnstileRoute{
			{Method: http.MethodPost, Path: "/v1/council/sessions"},
		},
	}

	// API routes with bot detection, Turnstile verification, rate limiting and body size limits.
	// The generated HandlerWithOptions registers the council + health OpenAPI routes.
	r.Group(func(r chi.Router) {
		// Bot detection - detects scraping bots via header analysis, behavioral patterns
		// and request rate analysis. Legitimate search engine bots are whitelisted.
		r.Use(botDetectionMiddleware(s.redis, s.logger, botConfig))

		// Turnstile verification - validates Cloudflare challenge tokens.
		r.Use(turnstileMiddleware(s.logger, turnstileConfig))

		// Tiered rate limiting - reads verification tier from context set by Turnstile middleware.
		r.Use(tieredRateLimitMiddleware(s.redis, s.logger))

		// Body size limit - 1MB max for API routes that accept bodies
		r.Use(bodySizeLimitMiddleware)

		// Mount OpenAPI-generated routes (council + health).
		HandlerWithOptions(s, ChiServerOptions{
			BaseRouter: r,
		})
	})

	return r
}
