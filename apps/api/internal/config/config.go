package config

import (
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"net"
	"net/url"
	"strings"
	"time"

	"github.com/kelseyhightower/envconfig"
	"golang.org/x/net/publicsuffix"
)

// Config is a flat structure - no nested configs until complexity demands it
type Config struct {
	AppName     string `envconfig:"APP_NAME" default:"lexicon-backend"`
	Environment string `envconfig:"ENVIRONMENT" default:"development"`
	LogLevel    string `envconfig:"LOG_LEVEL" default:"info"`
	Port        int    `envconfig:"PORT" default:"8000"`

	HTTPWriteTimeout time.Duration `envconfig:"HTTP_WRITE_TIMEOUT" default:"90s"`

	DatabaseURL      string `envconfig:"DATABASE_URL" required:"true"`
	DatabaseMaxConns int    `envconfig:"DATABASE_MAX_CONNS" default:"25"`

	RedisURL string `envconfig:"REDIS_URL" required:"true"`

	LLMServiceURL     string        `envconfig:"LLM_SERVICE_URL" required:"true"`
	LLMServiceTimeout time.Duration `envconfig:"LLM_SERVICE_TIMEOUT" default:"60s"`
	LLMAPIKey         string        `envconfig:"LLM_API_KEY" required:"true"`

	BaseURL string `envconfig:"BASE_URL" default:"http://localhost:8000"`

	// OpenTelemetry
	OTelEnabled    bool    `envconfig:"OTEL_ENABLED" default:"false"`
	OTelEndpoint   string  `envconfig:"OTLP_ENDPOINT" default:"localhost:4317"`
	OTelSampleRate float64 `envconfig:"OTEL_SAMPLE_RATE" default:"1.0"`
	ServiceVersion string  `envconfig:"SERVICE_VERSION" default:"0.1.0"`

	// S3-compatible Storage (GarageHQ)
	S3Endpoint        string        `envconfig:"S3_ENDPOINT" default:""`
	S3AccessKeyID     string        `envconfig:"S3_ACCESS_KEY_ID" default:""`
	S3SecretAccessKey string        `envconfig:"S3_SECRET_ACCESS_KEY" default:""`
	S3Bucket          string        `envconfig:"S3_BUCKET" default:""`
	S3Region          string        `envconfig:"S3_REGION" default:"garage"`
	S3PublicBaseURL   string        `envconfig:"S3_PUBLIC_BASE_URL" default:""`
	S3PresignExpiry   time.Duration `envconfig:"S3_PRESIGN_EXPIRY" default:"15m"`

	// ProcureLens Data Egress
	// API key for ProcureLens ETL to consume OCDS data
	// Generate with: openssl rand -hex 32
	ProcureLensAPIKey string `envconfig:"PROCURELENS_API_KEY" default:""`

	// OCDS Compiled JSON Export
	OCDSCompiledArtifactDir       string        `envconfig:"OCDS_COMPILED_ARTIFACT_DIR" default:"/tmp/lexicon-ocds-compiled"`
	OCDSCompiledArtifactTTL       time.Duration `envconfig:"OCDS_COMPILED_ARTIFACT_TTL" default:"6h"`
	OCDSCompiledWorkerConcurrency int           `envconfig:"OCDS_COMPILED_WORKER_CONCURRENCY" default:"1"`
	OCDSCompiledDefaultChunkSize  int           `envconfig:"OCDS_COMPILED_DEFAULT_CHUNK_SIZE" default:"5000"`
	OCDSCompiledMaxChunkSize      int           `envconfig:"OCDS_COMPILED_MAX_CHUNK_SIZE" default:"10000"`
	OCDSCompiledCleanupInterval   time.Duration `envconfig:"OCDS_COMPILED_CLEANUP_INTERVAL" default:"10m"`

	// Cloudflare Turnstile (server-side verification)
	TurnstileEnabled   bool   `envconfig:"TURNSTILE_ENABLED" default:"false"`
	TurnstileSecretKey string `envconfig:"TURNSTILE_SECRET_KEY" default:""`

	// Turnstile Graceful Degradation
	// HMAC secret key for signing session tokens (min 32 bytes, hex-encoded)
	// Generate with: openssl rand -hex 32
	TurnstileSessionSecret string `envconfig:"TURNSTILE_SESSION_SECRET" default:""`
	// App-level API key for frontend fallback when Turnstile widget fails
	// Generate with: openssl rand -hex 32
	TurnstileAppAPIKey string `envconfig:"TURNSTILE_APP_API_KEY" default:""`

	// Bot Detection
	// Enable/disable bot detection middleware
	BotDetectionEnabled bool `envconfig:"BOT_DETECTION_ENABLED" default:"true"`
	// Block detected bots with 429 (false = log only)
	BotDetectionBlockBots bool `envconfig:"BOT_DETECTION_BLOCK_BOTS" default:"true"`
	// Search:detail ratio threshold (e.g., 50 = 50 searches per 1 detail view)
	BotDetectionRatioThreshold float64 `envconfig:"BOT_DETECTION_RATIO_THRESHOLD" default:"50"`
	// Requests per minute threshold for behavioral flagging
	BotDetectionRateThreshold int `envconfig:"BOT_DETECTION_RATE_THRESHOLD" default:"60"`
	// Whitelist verified good bots (Googlebot, Bingbot, etc.)
	BotDetectionWhitelistGoodBots bool `envconfig:"BOT_DETECTION_WHITELIST_GOOD_BOTS" default:"true"`
	// Time window for behavioral analysis (1m-60m recommended)
	BotDetectionWindowDuration time.Duration `envconfig:"BOT_DETECTION_WINDOW_DURATION" default:"5m"`

	// Screening
	ScreeningScoreThreshold      float64       `envconfig:"SCREENING_SCORE_THRESHOLD" default:"0.70"`
	ScreeningScoreThresholdBroad float64       `envconfig:"SCREENING_SCORE_THRESHOLD_BROAD" default:"0.85"`
	ScreeningCacheSearchTTL      time.Duration `envconfig:"SCREENING_CACHE_SEARCH_TTL" default:"1h"`
	ScreeningCacheSourcesTTL     time.Duration `envconfig:"SCREENING_CACHE_SOURCES_TTL" default:"24h"`

	// OIDC Authentication (Authentik) — Admin (internal staff)
	// Leave AuthnAdminIssuer empty to disable OIDC (admin endpoints will return 503).
	// AuthnAdminClientSecret is only required for the BFF authorization-code flow
	// (/v1/admin/auth/login + /callback). Leave empty for pure resource-server mode.
	AuthnAdminIssuer          string        `envconfig:"AUTHN_ADMIN_ISSUER" default:""`
	AuthnAdminClientID        string        `envconfig:"AUTHN_ADMIN_CLIENT_ID" default:""`
	AuthnAdminClientSecret    string        `envconfig:"AUTHN_ADMIN_CLIENT_SECRET" default:""`
	AuthnAdminClaimPath       string        `envconfig:"AUTHN_ADMIN_CLAIM_PATH" default:"groups"`
	AuthnAdminRedirectURL     string        `envconfig:"AUTHN_ADMIN_REDIRECT_URL" default:""`
	AdminDashboardURL         string        `envconfig:"ADMIN_DASHBOARD_URL" default:""`
	AdminCookieDomain         string        `envconfig:"ADMIN_COOKIE_DOMAIN" default:""`
	AdminSessionEncryptionKey string        `envconfig:"ADMIN_SESSION_ENCRYPTION_KEY" default:""`
	AdminSessionTTL           time.Duration `envconfig:"ADMIN_SESSION_TTL" default:"24h"`
	AdminSessionRefreshLeeway time.Duration `envconfig:"ADMIN_SESSION_REFRESH_LEEWAY" default:"120s"`
	// AdminSessionAbsoluteTTL bounds the total lifetime of a session
	// regardless of activity. A stolen sid polled every few hours cannot
	// outlive this cap even though the rolling TTL keeps resetting.
	// Zero disables the cap (not recommended).
	AdminSessionAbsoluteTTL time.Duration `envconfig:"ADMIN_SESSION_ABSOLUTE_TTL" default:"12h"`

	// Crawler Service (optional admin reverse proxy)
	CrawlerBaseURL string `envconfig:"CRAWLER_BASE_URL" default:""`
	CrawlerAPIKey  string `envconfig:"CRAWLER_API_KEY" default:""`

	// CMS File Upload
	CMSFrontendBaseURL      string `envconfig:"CMS_FRONTEND_BASE_URL" default:"https://lexicon.id"`
	CMSMaxUploadSize        int64  `envconfig:"CMS_MAX_UPLOAD_SIZE" default:"52428800"`   // 50MB
	CMSMaxImageSize         int64  `envconfig:"CMS_MAX_IMAGE_SIZE" default:"10485760"`    // 10MB
	CMSMaxDocumentSize      int64  `envconfig:"CMS_MAX_DOCUMENT_SIZE" default:"52428800"` // 50MB
	CMSAllowedImageTypes    string `envconfig:"CMS_ALLOWED_IMAGE_TYPES" default:"image/jpeg,image/png,image/webp,image/gif"`
	CMSAllowedDocumentTypes string `envconfig:"CMS_ALLOWED_DOCUMENT_TYPES" default:"application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-powerpoint,application/vnd.openxmlformats-officedocument.presentationml.presentation,text/csv,text/plain,application/zip"`
}

func Load() (*Config, error) {
	var cfg Config
	if err := envconfig.Process("", &cfg); err != nil {
		return nil, err
	}
	if cfg.HTTPWriteTimeout < 0 {
		return nil, fmt.Errorf("HTTP_WRITE_TIMEOUT must be greater than or equal to 0")
	}

	// Validate LLM service URL to prevent SSRF attacks
	if err := validateLLMServiceURL(cfg.LLMServiceURL, cfg.Environment); err != nil {
		return nil, fmt.Errorf("invalid LLM_SERVICE_URL: %w", err)
	}

	// Validate S3 endpoint if provided
	if cfg.S3Endpoint != "" {
		if err := validateS3Endpoint(cfg.S3Endpoint, cfg.Environment); err != nil {
			return nil, fmt.Errorf("invalid S3_ENDPOINT: %w", err)
		}
	}
	if cfg.S3PublicBaseURL != "" {
		if err := validatePublicBaseURL(cfg.S3PublicBaseURL, cfg.Environment); err != nil {
			return nil, fmt.Errorf("invalid S3_PUBLIC_BASE_URL: %w", err)
		}
	}
	if err := validateAbsoluteHTTPURL(cfg.CMSFrontendBaseURL); err != nil {
		return nil, fmt.Errorf("invalid CMS_FRONTEND_BASE_URL: %w", err)
	}
	cfg.CMSFrontendBaseURL = strings.TrimRight(cfg.CMSFrontendBaseURL, "/")

	// Validate OIDC: if admin issuer is set, admin client ID is required
	if cfg.AuthnAdminIssuer != "" {
		if cfg.Environment == "production" && isForbiddenProductionAdminIssuer(cfg.AuthnAdminIssuer) {
			return nil, fmt.Errorf("AUTHN_ADMIN_ISSUER must not point at .invalid hosts in production")
		}
		if cfg.AuthnAdminClientID == "" {
			return nil, fmt.Errorf("AUTHN_ADMIN_CLIENT_ID is required when AUTHN_ADMIN_ISSUER is set")
		}
	}
	if cfg.AuthnAdminClientSecret != "" {
		if cfg.AuthnAdminIssuer == "" {
			return nil, fmt.Errorf("AUTHN_ADMIN_ISSUER is required when AUTHN_ADMIN_CLIENT_SECRET is set")
		}
		if cfg.AdminSessionEncryptionKey == "" {
			return nil, fmt.Errorf("ADMIN_SESSION_ENCRYPTION_KEY is required when AUTHN_ADMIN_CLIENT_SECRET is set")
		}
		decodedKey, err := DecodeAdminSessionEncryptionKey(cfg.AdminSessionEncryptionKey)
		if err != nil {
			return nil, fmt.Errorf("invalid ADMIN_SESSION_ENCRYPTION_KEY: %w", err)
		}
		if len(decodedKey) != 32 {
			return nil, fmt.Errorf("ADMIN_SESSION_ENCRYPTION_KEY must decode to exactly 32 bytes, got %d", len(decodedKey))
		}
		if cfg.AuthnAdminRedirectURL == "" {
			return nil, fmt.Errorf("AUTHN_ADMIN_REDIRECT_URL is required when AUTHN_ADMIN_CLIENT_SECRET is set")
		}
		if err := validateAbsoluteHTTPURL(cfg.AuthnAdminRedirectURL); err != nil {
			return nil, fmt.Errorf("invalid AUTHN_ADMIN_REDIRECT_URL: %w", err)
		}
		if cfg.AdminDashboardURL == "" {
			return nil, fmt.Errorf("ADMIN_DASHBOARD_URL is required when AUTHN_ADMIN_CLIENT_SECRET is set")
		}
		if err := validateAbsoluteHTTPURL(cfg.AdminDashboardURL); err != nil {
			return nil, fmt.Errorf("invalid ADMIN_DASHBOARD_URL: %w", err)
		}
		if cfg.AdminCookieDomain != "" {
			if err := validateAdminCookieDomain(cfg.AdminCookieDomain, cfg.AuthnAdminRedirectURL, cfg.AdminDashboardURL); err != nil {
				return nil, fmt.Errorf("invalid ADMIN_COOKIE_DOMAIN: %w", err)
			}
			// Normalize: strip a single leading "." and lowercase so set/clear
			// emit identical Domain attributes (RFC 6265 §5.3) regardless of
			// the operator's input style.
			cfg.AdminCookieDomain = strings.ToLower(strings.TrimPrefix(cfg.AdminCookieDomain, "."))
		} else {
			redirectHost, err := absoluteHTTPURLHostname(cfg.AuthnAdminRedirectURL)
			if err != nil {
				return nil, fmt.Errorf("invalid AUTHN_ADMIN_REDIRECT_URL: %w", err)
			}
			dashboardHost, err := absoluteHTTPURLHostname(cfg.AdminDashboardURL)
			if err != nil {
				return nil, fmt.Errorf("invalid ADMIN_DASHBOARD_URL: %w", err)
			}
			if redirectHost != dashboardHost {
				return nil, fmt.Errorf("ADMIN_COOKIE_DOMAIN is required when AUTHN_ADMIN_REDIRECT_URL and ADMIN_DASHBOARD_URL hosts differ (got %q vs %q)", redirectHost, dashboardHost)
			}
		}
		if cfg.AdminSessionTTL <= 0 {
			return nil, fmt.Errorf("ADMIN_SESSION_TTL must be greater than 0")
		}
		if cfg.AdminSessionRefreshLeeway < 0 {
			return nil, fmt.Errorf("ADMIN_SESSION_REFRESH_LEEWAY must be greater than or equal to 0")
		}
		if cfg.AdminSessionAbsoluteTTL < 0 {
			return nil, fmt.Errorf("ADMIN_SESSION_ABSOLUTE_TTL must be greater than or equal to 0")
		}
	}

	// Validate Turnstile: all keys required when enabled
	if cfg.TurnstileEnabled {
		if cfg.TurnstileSecretKey == "" {
			return nil, fmt.Errorf("TURNSTILE_SECRET_KEY is required when TURNSTILE_ENABLED=true")
		}
		if cfg.TurnstileSessionSecret == "" {
			return nil, fmt.Errorf("TURNSTILE_SESSION_SECRET is required when TURNSTILE_ENABLED=true")
		}
		if len(cfg.TurnstileSessionSecret) < 64 {
			return nil, fmt.Errorf("TURNSTILE_SESSION_SECRET must be at least 32 bytes (64 hex chars), got %d chars", len(cfg.TurnstileSessionSecret))
		}
		if _, err := hex.DecodeString(cfg.TurnstileSessionSecret); err != nil {
			return nil, fmt.Errorf("TURNSTILE_SESSION_SECRET must be a valid hex-encoded string: %w", err)
		}
		if cfg.TurnstileAppAPIKey == "" {
			return nil, fmt.Errorf("TURNSTILE_APP_API_KEY is required when TURNSTILE_ENABLED=true")
		}
	}

	if strings.TrimSpace(cfg.OCDSCompiledArtifactDir) == "" {
		return nil, fmt.Errorf("OCDS_COMPILED_ARTIFACT_DIR must not be empty")
	}
	if cfg.OCDSCompiledArtifactTTL <= 0 {
		return nil, fmt.Errorf("OCDS_COMPILED_ARTIFACT_TTL must be greater than 0")
	}
	if cfg.OCDSCompiledWorkerConcurrency < 1 {
		return nil, fmt.Errorf("OCDS_COMPILED_WORKER_CONCURRENCY must be at least 1")
	}
	if cfg.OCDSCompiledDefaultChunkSize < 1 {
		return nil, fmt.Errorf("OCDS_COMPILED_DEFAULT_CHUNK_SIZE must be at least 1")
	}
	if cfg.OCDSCompiledMaxChunkSize < 1 {
		return nil, fmt.Errorf("OCDS_COMPILED_MAX_CHUNK_SIZE must be at least 1")
	}
	if cfg.OCDSCompiledDefaultChunkSize > cfg.OCDSCompiledMaxChunkSize {
		return nil, fmt.Errorf("OCDS_COMPILED_DEFAULT_CHUNK_SIZE must be less than or equal to OCDS_COMPILED_MAX_CHUNK_SIZE")
	}
	if cfg.OCDSCompiledCleanupInterval <= 0 {
		return nil, fmt.Errorf("OCDS_COMPILED_CLEANUP_INTERVAL must be greater than 0")
	}

	return &cfg, nil
}

func DecodeAdminSessionEncryptionKey(value string) ([]byte, error) {
	if value == "" {
		return nil, fmt.Errorf("value is empty")
	}
	if decoded, err := base64.StdEncoding.DecodeString(value); err == nil {
		return decoded, nil
	}
	if decoded, err := base64.RawStdEncoding.DecodeString(value); err == nil {
		return decoded, nil
	}
	return nil, fmt.Errorf("must be valid base64")
}

func validateAbsoluteHTTPURL(urlStr string) error {
	u, err := url.Parse(urlStr)
	if err != nil {
		return fmt.Errorf("invalid URL format: %w", err)
	}
	if !u.IsAbs() {
		return fmt.Errorf("URL must be absolute")
	}
	if u.Scheme != "http" && u.Scheme != "https" {
		return fmt.Errorf("invalid URL scheme: %s (must be http or https)", u.Scheme)
	}
	if u.Host == "" {
		return fmt.Errorf("host is required")
	}
	return nil
}

func validateAdminCookieDomain(domain, redirectURL, dashboardURL string) error {
	if strings.Contains(domain, "://") {
		return fmt.Errorf("domain must not include a URL scheme")
	}
	// DNS is case-insensitive; lowercase early so the hostname grammar check
	// accepts operator input like `Lexicon.id` instead of rejecting it as
	// "invalid character 'L'".
	normalizedDomain := strings.ToLower(strings.TrimPrefix(domain, "."))
	if normalizedDomain == "" {
		return fmt.Errorf("domain must not be empty")
	}
	if strings.TrimSpace(normalizedDomain) != normalizedDomain {
		return fmt.Errorf("domain must not contain leading or trailing whitespace")
	}
	if strings.ContainsAny(normalizedDomain, ":/") {
		return fmt.Errorf("domain must not include a port or path")
	}
	if err := validateCookieDomainHostname(normalizedDomain); err != nil {
		return err
	}
	if suffix, _ := publicsuffix.PublicSuffix(normalizedDomain); suffix == normalizedDomain {
		return fmt.Errorf("domain must not be a public suffix")
	}

	for _, rawURL := range []string{redirectURL, dashboardURL} {
		host, err := absoluteHTTPURLHostname(rawURL)
		if err != nil {
			return err
		}
		if !cookieDomainCoversHost(normalizedDomain, host) {
			return fmt.Errorf("%q must be a suffix of %q", domain, host)
		}
	}
	return nil
}

func validateCookieDomainHostname(hostname string) error {
	if len(hostname) > 253 {
		return fmt.Errorf("domain is too long")
	}
	for _, label := range strings.Split(hostname, ".") {
		if label == "" {
			return fmt.Errorf("domain contains an empty label")
		}
		if len(label) > 63 {
			return fmt.Errorf("domain label %q is too long", label)
		}
		if strings.HasPrefix(label, "-") || strings.HasSuffix(label, "-") {
			return fmt.Errorf("domain label %q must not start or end with hyphen", label)
		}
		for _, ch := range label {
			if (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || ch == '-' {
				continue
			}
			return fmt.Errorf("domain contains invalid character %q", ch)
		}
	}
	return nil
}

func cookieDomainCoversHost(domain, host string) bool {
	return host == domain || strings.HasSuffix(host, "."+domain)
}

func absoluteHTTPURLHostname(urlStr string) (string, error) {
	u, err := url.Parse(urlStr)
	if err != nil {
		return "", fmt.Errorf("invalid URL format: %w", err)
	}
	if u.Host == "" {
		return "", fmt.Errorf("host is required")
	}
	return strings.ToLower(u.Hostname()), nil
}

func isForbiddenProductionAdminIssuer(rawURL string) bool {
	u, err := url.Parse(rawURL)
	if err != nil {
		return true
	}
	host := strings.ToLower(u.Hostname())
	return host == "invalid" || strings.HasSuffix(host, ".invalid")
}

func validatePublicBaseURL(urlStr string, environment string) error {
	u, err := url.Parse(urlStr)
	if err != nil {
		return fmt.Errorf("invalid URL format: %w", err)
	}
	if u.Scheme != "http" && u.Scheme != "https" {
		return fmt.Errorf("invalid URL scheme: %s (must be http or https)", u.Scheme)
	}
	if u.Host == "" {
		return fmt.Errorf("host is required")
	}

	// Block private IPs in production — URL value is stored in DB and returned to clients
	if environment == "production" {
		hostname := u.Hostname()
		ips, err := net.LookupIP(hostname)
		if err != nil {
			return fmt.Errorf("failed to resolve host %q: %w", hostname, err)
		}
		for _, ip := range ips {
			if ip.IsLoopback() || ip.IsPrivate() || ip.IsLinkLocalUnicast() {
				return fmt.Errorf("private/loopback IP not allowed in production: %s -> %s", hostname, ip)
			}
			if isCloudMetadataIP(ip) {
				return fmt.Errorf("cloud metadata IP not allowed: %s -> %s", hostname, ip)
			}
		}
	}

	return nil
}

// validateChatbotURL validates the chatbot service URL against allowed hosts
// to prevent Server-Side Request Forgery (SSRF) attacks
func validateChatbotURL(urlStr string, environment string) error {
	u, err := url.Parse(urlStr)
	if err != nil {
		return fmt.Errorf("invalid URL format: %w", err)
	}

	// Ensure scheme is http or https
	if u.Scheme != "http" && u.Scheme != "https" {
		return fmt.Errorf("invalid URL scheme: %s (must be http or https)", u.Scheme)
	}

	// Whitelist allowed hosts based on environment
	allowedHosts := GetAllowedChatbotHosts(environment)

	// Check if host is whitelisted
	if !urlHostAllowed(u, allowedHosts) {
		return fmt.Errorf("host not whitelisted: %s (allowed: %v)", u.Host, allowedHosts)
	}

	// Additional check: prevent private IPs even if somehow in whitelist
	hostname := u.Hostname()
	ip := net.ParseIP(hostname)
	if ip != nil {
		if ip.IsPrivate() || ip.IsLoopback() {
			// Allow private IPs only in development environment
			if environment != "development" {
				return fmt.Errorf("private/loopback IP addresses not allowed in %s environment", environment)
			}
		}

		// Always block cloud metadata endpoints (AWS, GCP, Azure)
		if isCloudMetadataIP(ip) {
			return fmt.Errorf("cloud metadata IP addresses are not allowed: %s", ip.String())
		}
	}

	return nil
}

// GetAllowedChatbotHosts returns the whitelist of allowed chatbot service hosts
// Exported for use in secure HTTP client DNS rebinding protection
func GetAllowedChatbotHosts(environment string) []string {
	// Development environment allows localhost for testing
	if environment == "development" {
		return []string{
			"localhost",
			"localhost:8001",
			"127.0.0.1",
			"127.0.0.1:8001",
			"chatbot.lexicon.id",
			"chatbot.justicia.id",
		}
	}

	// Production and staging environments use only production hosts
	if environment == "staging" {
		return []string{
			"chatbot.justicia.id",
			"chatbot.lexicon.id",
		}
	}

	// Production
	return []string{
		"chatbot.lexicon.id",
	}
}

// LLMServiceURLClass describes how the configured LLM URL should be reached.
type LLMServiceURLClass string

const (
	LLMServiceURLPublicOutbound   LLMServiceURLClass = "public_outbound"
	LLMServiceURLInternalService  LLMServiceURLClass = "internal_service"
	LLMServiceURLDevelopmentLocal LLMServiceURLClass = "development_local"
)

// validateLLMServiceURL validates the LLM service URL against allowed hosts
// to prevent Server-Side Request Forgery (SSRF) attacks
func validateLLMServiceURL(urlStr string, environment string) error {
	_, err := ClassifyLLMServiceURL(urlStr, environment)
	return err
}

// ClassifyLLMServiceURL validates and classifies the LLM service URL so call
// sites can select an explicit outbound HTTP policy.
func ClassifyLLMServiceURL(urlStr string, environment string) (LLMServiceURLClass, error) {
	u, err := url.Parse(urlStr)
	if err != nil {
		return "", fmt.Errorf("invalid URL format: %w", err)
	}

	// Ensure scheme is http or https
	if u.Scheme != "http" && u.Scheme != "https" {
		return "", fmt.Errorf("invalid URL scheme: %s (must be http or https)", u.Scheme)
	}

	if urlHostAllowed(u, GetAllowedDevelopmentLocalLLMServiceHosts()) {
		if environment == "development" {
			return LLMServiceURLDevelopmentLocal, nil
		}
		return "", fmt.Errorf("development-local LLM host not allowed in %s environment: %s", environment, u.Host)
	}

	if urlHostAllowed(u, GetAllowedInternalLLMServiceHosts(environment)) {
		return LLMServiceURLInternalService, nil
	}

	if urlHostAllowed(u, GetAllowedPublicLLMServiceHosts(environment)) {
		return LLMServiceURLPublicOutbound, nil
	}

	return "", fmt.Errorf("host not whitelisted: %s (allowed: %v)", u.Host, GetAllowedLLMServiceHosts(environment))
}

// GetAllowedDevelopmentLocalLLMServiceHosts returns LLM hosts reserved for
// local development only.
func GetAllowedDevelopmentLocalLLMServiceHosts() []string {
	return []string{
		"localhost",
		"localhost:8001",
		"127.0.0.1",
		"127.0.0.1:8001",
	}
}

// GetAllowedInternalLLMServiceHosts returns first-party service hostnames that
// may be reached through the internal-service HTTP policy.
func GetAllowedInternalLLMServiceHosts(environment string) []string {
	return []string{
		"llm",
		"llm:8001",
	}
}

// GetAllowedPublicLLMServiceHosts returns public LLM service hostnames.
func GetAllowedPublicLLMServiceHosts(environment string) []string {
	return []string{
		"llm.lexicon.id",
		"llm.justicia.id",
	}
}

// GetAllowedLLMServiceHosts returns the whitelist of allowed LLM service hosts
// Exported for use in secure HTTP client DNS rebinding protection
func GetAllowedLLMServiceHosts(environment string) []string {
	hosts := append([]string{}, GetAllowedInternalLLMServiceHosts(environment)...)
	hosts = append(hosts, GetAllowedPublicLLMServiceHosts(environment)...)
	if environment == "development" {
		hosts = append(GetAllowedDevelopmentLocalLLMServiceHosts(), hosts...)
	}
	return hosts
}

func urlHostAllowed(u *url.URL, allowedHosts []string) bool {
	host := strings.ToLower(strings.TrimSpace(u.Host))
	hostname := strings.ToLower(strings.TrimSpace(u.Hostname()))
	for _, allowedHost := range allowedHosts {
		allowedHost = strings.ToLower(strings.TrimSpace(allowedHost))
		if allowedHost == "" {
			continue
		}
		if host == allowedHost || hostname == allowedHost {
			return true
		}
	}
	return false
}

// isCloudMetadataIP checks if an IP is a cloud metadata endpoint
func isCloudMetadataIP(ip net.IP) bool {
	// AWS metadata endpoint: 169.254.169.254
	if ip.String() == "169.254.169.254" {
		return true
	}

	// GCP metadata endpoint: metadata.google.internal (169.254.169.254)
	// Azure metadata endpoint: 169.254.169.254
	// Link-local addresses (169.254.0.0/16) are often used for metadata
	if ip.IsLinkLocalUnicast() {
		return true
	}

	return false
}

// validateS3Endpoint validates the S3 endpoint URL to prevent SSRF attacks
// S3 is optional - empty endpoint means storage is disabled
func validateS3Endpoint(urlStr string, environment string) error {
	if urlStr == "" {
		return nil // Optional, disabled
	}

	u, err := url.Parse(urlStr)
	if err != nil {
		return fmt.Errorf("invalid URL format: %w", err)
	}

	// Ensure scheme is http or https
	if u.Scheme != "http" && u.Scheme != "https" {
		return fmt.Errorf("invalid URL scheme: %s (must be http or https)", u.Scheme)
	}

	// Check for cloud metadata endpoints
	hostname := u.Hostname()
	ip := net.ParseIP(hostname)
	if ip != nil {
		if isCloudMetadataIP(ip) {
			return fmt.Errorf("cloud metadata IP addresses are not allowed: %s", ip.String())
		}
		// Allow private IPs only in development (for local GarageHQ)
		if ip.IsPrivate() || ip.IsLoopback() {
			if environment != "development" {
				return fmt.Errorf("private/loopback IP addresses not allowed in %s environment", environment)
			}
		}
	}

	return nil
}
