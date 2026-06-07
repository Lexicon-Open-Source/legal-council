package api

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"io"
	"log/slog"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/lexiconindonesia/lexicon-backend/internal/i18n"
)

// turnstileHeader is the HTTP header containing the Turnstile challenge token.
const turnstileHeader = "X-Turnstile-Token"

// turnstileSiteverifyURL is the Cloudflare Turnstile server-side verification endpoint.
const turnstileSiteverifyURL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

// turnstileMaxTokenLength is the maximum allowed length of a Turnstile token.
// Cloudflare tokens are typically ~2KB; reject anything larger to prevent abuse.
const turnstileMaxTokenLength = 2048

// turnstileMaxResponseBody is the maximum response body size from Cloudflare's siteverify.
// Valid responses are ~200 bytes; 4KB is generous while preventing unbounded reads.
const turnstileMaxResponseBody = 4096

// turnstileSessionHeader is the HTTP header for the HMAC session token.
// Sent as a response header after successful Turnstile verification,
// and as a request header on subsequent requests to bypass Turnstile.
const turnstileSessionHeader = "X-Turnstile-Session"

// turnstileAppKeyHeader is the HTTP header for the app-level API key fallback.
// Used when neither Turnstile token nor session token is available.
const turnstileAppKeyHeader = "X-Turnstile-App-Key"

// turnstileRoute defines a method+path pair that requires Turnstile verification.
type turnstileRoute struct {
	Method string
	Path   string
}

// TurnstileConfig configures the Turnstile verification middleware.
type TurnstileConfig struct {
	Enabled   bool
	SecretKey string

	// ProtectedRoutes lists the specific method+path pairs that require Turnstile
	// verification. When empty, ALL routes are protected (backward-compatible).
	ProtectedRoutes []turnstileRoute

	// AllowedHostnames lists the domains where the Turnstile widget may be rendered.
	// Cloudflare's siteverify response includes the hostname; we verify it matches
	// one of these. When empty, hostname verification is skipped (e.g., development).
	AllowedHostnames []string

	// Session token settings (graceful degradation tier 2)
	SessionSecret []byte        // HMAC-SHA256 signing key (raw bytes from hex-decoded env var)
	SessionTTL    time.Duration // Token validity duration (default: 5 minutes)
	SessionGrace  time.Duration // Clock-skew tolerance on expiry (default: 30 seconds)

	// App API key fallback (graceful degradation tier 3)
	AppAPIKey string

	// VerifyURL overrides the Cloudflare siteverify URL (for testing).
	// Defaults to turnstileSiteverifyURL when empty.
	VerifyURL string

	// HTTPClient overrides the default HTTP client (for testing).
	// Defaults to a 5s-timeout, no-redirect client when nil.
	HTTPClient *http.Client
}

// turnstileSiteverifyResponse is the response from Cloudflare's siteverify endpoint.
type turnstileSiteverifyResponse struct {
	Success    bool     `json:"success"`
	Hostname   string   `json:"hostname"`
	ErrorCodes []string `json:"error-codes"`
}

// turnstileMiddleware verifies Cloudflare Turnstile tokens on incoming requests.
// When disabled (TurnstileConfig.Enabled=false), all requests pass through.
// When Cloudflare is unreachable, requests fail open with a warning log.
// Fail-open rationale: Cloudflare is an external third-party service outside operator
// control. A Cloudflare outage should not block all users. Bot detection and rate
// limiting still provide protection when Turnstile fails open. This differs from
// rate limiting (fail-closed) because Redis is owned infrastructure.
func turnstileMiddleware(logger *slog.Logger, cfg TurnstileConfig) func(http.Handler) http.Handler {
	// Resolve defaults for injectable fields
	verifyURL := cfg.VerifyURL
	if verifyURL == "" {
		verifyURL = turnstileSiteverifyURL
	}

	client := cfg.HTTPClient
	if client == nil {
		// Dedicated HTTP client for Turnstile verification.
		// Not using httpclient.SecureClient because the target URL is hardcoded
		// (no SSRF risk) and we want independent timeout control.
		client = &http.Client{
			Timeout: 5 * time.Second,
			Transport: &http.Transport{
				MaxIdleConns:          50,
				MaxIdleConnsPerHost:   50, // All connections go to one host (Cloudflare)
				IdleConnTimeout:       90 * time.Second,
				TLSHandshakeTimeout:   3 * time.Second,
				ExpectContinueTimeout: 1 * time.Second,
			},
			// Disable redirects: siteverify should never redirect.
			// Prevents secret key leakage via redirect to attacker-controlled server.
			CheckRedirect: func(req *http.Request, via []*http.Request) error {
				return http.ErrUseLastResponse
			},
		}
	}

	// Build session config for HMAC token operations.
	sessionCfg := turnstileSessionConfig{
		SecretKey:   cfg.SessionSecret,
		TTL:         cfg.SessionTTL,
		GracePeriod: cfg.SessionGrace,
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Pass through if Turnstile is disabled (e.g., development)
			if !cfg.Enabled {
				next.ServeHTTP(w, r)
				return
			}

			// Skip verification for routes not in the protected list.
			// When ProtectedRoutes is empty, all routes are protected.
			if len(cfg.ProtectedRoutes) > 0 {
				protected := false
				for _, route := range cfg.ProtectedRoutes {
					if r.Method == route.Method && r.URL.Path == route.Path {
						protected = true
						break
					}
				}
				if !protected {
					next.ServeHTTP(w, r)
					return
				}
			}

			ctx := r.Context()

			// === Tier 1: Turnstile token verification ===
			token := r.Header.Get(turnstileHeader)
			if token != "" {
				tier, issueSession := verifyTurnstileToken(w, logger, client, verifyURL, cfg, token, r)
				if tier == "" {
					// Verification failed with a hard rejection (403 already sent)
					return
				}

				ctx = context.WithValue(ctx, turnstileVerificationTierKey{}, tier)

				// Issue session token on successful Cloudflare verification.
				// NOT issued on fail-open (prevents harvesting without solving challenge).
				if issueSession {
					if sessionToken, err := generateSessionToken(sessionCfg); err == nil {
						w.Header().Set(turnstileSessionHeader, sessionToken)
					} else {
						logger.Warn("failed to generate session token", "error", err)
					}
				}

				logger.Debug("turnstile verification passed",
					"tier", tier,
					"path", r.URL.Path,
				)
				next.ServeHTTP(w, r.WithContext(ctx))
				return
			}

			// === Tier 2: Session token verification ===
			sessionToken := r.Header.Get(turnstileSessionHeader)
			if sessionToken != "" {
				if err := verifySessionToken(sessionCfg, sessionToken); err == nil {
					ctx = context.WithValue(ctx, turnstileVerificationTierKey{}, verificationTierSession)
					logger.Debug("session token verification passed",
						"tier", verificationTierSession,
						"path", r.URL.Path,
					)
					next.ServeHTTP(w, r.WithContext(ctx))
					return
				} else {
					logger.Debug("session token verification failed, falling through",
						"error", err,
						"path", r.URL.Path,
					)
				}
				// Invalid/expired session token — fall through to tier 3.
				// Don't return 403 here; give the app key a chance.
			}

			// === Tier 3: App API key fallback ===
			appKey := r.Header.Get(turnstileAppKeyHeader)
			if appKey != "" && cfg.AppAPIKey != "" {
				if subtle.ConstantTimeCompare([]byte(appKey), []byte(cfg.AppAPIKey)) == 1 {
					ctx = context.WithValue(ctx, turnstileVerificationTierKey{}, verificationTierAppKey)
					logger.Debug("app key verification passed",
						"tier", verificationTierAppKey,
						"path", r.URL.Path,
					)
					next.ServeHTTP(w, r.WithContext(ctx))
					return
				}
				// Invalid app key — reject
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusForbidden)
				_ = json.NewEncoder(w).Encode(map[string]string{
					"error": i18n.T(ctx, i18n.MsgErrorAppKeyInvalid),
				})
				return
			}

			// === No credentials — reject ===
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusForbidden)
			_ = json.NewEncoder(w).Encode(map[string]string{
				"error": i18n.T(ctx, i18n.MsgErrorTurnstileMissing),
			})
		})
	}
}

// verifyTurnstileToken handles Cloudflare siteverify for the Turnstile token.
// Returns the verification tier and whether a session token should be issued.
// Returns ("", false) on hard rejection (403 has been written to w).
func verifyTurnstileToken(w http.ResponseWriter, logger *slog.Logger, client *http.Client, verifyURL string, cfg TurnstileConfig, token string, r *http.Request) (tier string, issueSession bool) {
	ctx := r.Context()

	// Reject oversized tokens
	if len(token) > turnstileMaxTokenLength {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"error": i18n.T(ctx, i18n.MsgErrorTurnstileFailed),
		})
		return "", false
	}

	// Extract remote IP
	remoteIP := r.RemoteAddr
	if host, _, err := net.SplitHostPort(remoteIP); err == nil {
		remoteIP = host
	}

	formData := url.Values{
		"secret":   {cfg.SecretKey},
		"response": {token},
		"remoteip": {remoteIP},
	}

	resp, err := client.PostForm(verifyURL, formData)
	if err != nil {
		// Fail open: Cloudflare unreachable — NO session token issued
		logger.Warn("Turnstile verification failed: Cloudflare unreachable",
			"error", err,
			"remote_ip", remoteIP,
		)
		return verificationTierTurnstile, false
	}
	defer func() { _ = resp.Body.Close() }()

	limitedBody := io.LimitReader(resp.Body, turnstileMaxResponseBody)

	var result turnstileSiteverifyResponse
	if err := json.NewDecoder(limitedBody).Decode(&result); err != nil {
		// Fail open: can't parse response — NO session token issued
		logger.Warn("Turnstile verification failed: invalid response",
			"error", err,
			"remote_ip", remoteIP,
		)
		return verificationTierTurnstile, false
	}

	if !result.Success {
		logger.Info("Turnstile verification rejected",
			"remote_ip", remoteIP,
			"error_codes", result.ErrorCodes,
		)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"error": i18n.T(ctx, i18n.MsgErrorTurnstileFailed),
		})
		return "", false
	}

	// Verify hostname matches an allowed domain
	if len(cfg.AllowedHostnames) > 0 {
		hostnameAllowed := false
		for _, allowed := range cfg.AllowedHostnames {
			if result.Hostname == allowed || strings.HasSuffix(result.Hostname, "."+allowed) {
				hostnameAllowed = true
				break
			}
		}
		if !hostnameAllowed {
			logger.Info("Turnstile hostname mismatch",
				"remote_ip", remoteIP,
				"allowed", cfg.AllowedHostnames,
				"actual", result.Hostname,
			)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusForbidden)
			_ = json.NewEncoder(w).Encode(map[string]string{
				"error": i18n.T(ctx, i18n.MsgErrorTurnstileFailed),
			})
			return "", false
		}
	}

	// Cloudflare verification succeeded — issue session token
	return verificationTierTurnstile, true
}
