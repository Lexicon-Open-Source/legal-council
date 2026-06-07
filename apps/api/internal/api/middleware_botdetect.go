package api

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// DNSResolver provides an interface for DNS lookups, allowing mocking in tests.
type DNSResolver interface {
	// LookupAddr performs a reverse DNS lookup for the given address.
	LookupAddr(ctx context.Context, addr string) ([]string, error)
	// LookupHost performs a forward DNS lookup for the given host.
	LookupHost(ctx context.Context, host string) ([]string, error)
}

// netDNSResolver wraps net.DefaultResolver to implement DNSResolver.
type netDNSResolver struct{}

func (r *netDNSResolver) LookupAddr(ctx context.Context, addr string) ([]string, error) {
	return net.DefaultResolver.LookupAddr(ctx, addr)
}

func (r *netDNSResolver) LookupHost(ctx context.Context, host string) ([]string, error) {
	return net.DefaultResolver.LookupHost(ctx, host)
}

// defaultDNSResolver is the package-level DNS resolver used by verifyBotDNS.
// It can be replaced in tests with a mock implementation.
var defaultDNSResolver DNSResolver = &netDNSResolver{}

// DNS verification cache to prevent DoS via repeated DNS lookups.
// Key: IP address, Value: dnsCacheEntry
var dnsVerificationCache sync.Map

// dnsCacheEntry stores a cached DNS verification result with expiration.
type dnsCacheEntry struct {
	verified bool
	expiry   time.Time
}

// DNS lookup timeout to prevent slow resolver blocking (2 seconds as per requirements).
const dnsLookupTimeout = 2 * time.Second

// DNS cache TTL - how long to cache verification results (1 hour as per requirements).
const dnsCacheTTL = 1 * time.Hour

// clearDNSCache clears the DNS verification cache (for testing).
func clearDNSCache() {
	dnsVerificationCache.Range(func(key, value interface{}) bool {
		dnsVerificationCache.Delete(key)
		return true
	})
}

// BotDetectionConfig configures the bot detection middleware
type BotDetectionConfig struct {
	// Enabled controls whether bot detection is active
	Enabled bool
	// BlockBots determines whether to block detected bots (429) or just log them
	BlockBots bool
	// SearchDetailRatioThreshold is the max search:detail ratio before flagging as bot
	// A ratio of 100 means 100 search requests per 1 detail request
	SearchDetailRatioThreshold float64
	// RequestsPerMinuteThreshold is the max requests/min before behavioral flagging
	RequestsPerMinuteThreshold int
	// WindowDuration is the time window for behavioral analysis
	WindowDuration time.Duration
	// WhitelistGoodBots enables verification of legitimate search engine bots
	WhitelistGoodBots bool
}

// DefaultBotDetectionConfig returns sensible defaults
func DefaultBotDetectionConfig() BotDetectionConfig {
	return BotDetectionConfig{
		Enabled:                    true,
		BlockBots:                  true,
		SearchDetailRatioThreshold: 50.0, // 50 searches per 1 detail view
		RequestsPerMinuteThreshold: 60,   // 60 req/min sustained
		WindowDuration:             5 * time.Minute,
		WhitelistGoodBots:          true,
	}
}

// botSignal represents a single detection signal
type botSignal struct {
	Name       string  `json:"name"`
	Triggered  bool    `json:"triggered"`
	Confidence float64 `json:"confidence"` // 0.0 to 1.0
	Details    string  `json:"details,omitempty"`
}

// botDetectionResult aggregates all signals
type botDetectionResult struct {
	IsBot           bool        `json:"is_bot"`
	TotalConfidence float64     `json:"total_confidence"`
	Signals         []botSignal `json:"signals"`
	IP              string      `json:"ip"`
	UserAgent       string      `json:"user_agent"`
	IsGoodBot       bool        `json:"is_good_bot"`
	GoodBotName     string      `json:"good_bot_name,omitempty"`
}

// Redis key prefixes for bot detection
const (
	botDetectKeyPrefix     = "botdetect:"
	botDetectSearchCount   = "search:"
	botDetectDetailCount   = "detail:"
	botDetectRequestCount  = "requests:"
	botDetectBlockedPrefix = "blocked:"
)

// Bot detection signal weights and thresholds.
// See ADR-0015 for rationale on these values.
const (
	// headerAnalysisWeight is the weight for header-based bot signals.
	// Real browsers send consistent headers (Accept-Language, Sec-Fetch-*, etc.).
	headerAnalysisWeight = 0.25

	// userAgentWeight is the weight for User-Agent analysis signals.
	// Easy to spoof but catches lazy bots using default library UAs.
	userAgentWeight = 0.20

	// searchDetailRatioWeight is the weight for search:detail ratio signals.
	// Most reliable scraper indicator - scrapers enumerate without viewing details.
	searchDetailRatioWeight = 0.35

	// requestRateWeight is the weight for request rate pattern signals.
	// Supplements ratio analysis for sustained high-volume traffic.
	requestRateWeight = 0.20

	// confidenceThreshold is the minimum total confidence to classify as bot.
	// Set at 60% to balance detection vs false positives.
	confidenceThreshold = 0.60
)

// incrWithTTLScript atomically increments a key and sets TTL only on creation.
// This prevents race conditions where a key could persist indefinitely if a crash
// occurs between separate INCR and EXPIRE commands.
// Returns the new value after increment.
var incrWithTTLScript = redis.NewScript(`
	local val = redis.call('INCR', KEYS[1])
	if val == 1 then
		redis.call('EXPIRE', KEYS[1], ARGV[1])
	end
	return val
`)

// atomicIncrWithTTL increments a key and sets TTL atomically.
// TTL is only set when the key is newly created (value becomes 1).
func atomicIncrWithTTL(ctx context.Context, redisClient *redis.Client, key string, ttl time.Duration) (int64, error) {
	return incrWithTTLScript.Run(ctx, redisClient, []string{key}, int(ttl.Seconds())).Int64()
}

// Search and detail path patterns
var (
	searchPathPatterns = []string{
		"/v1/beneficial-ownership/search",
		"/v1/beneficial-ownership/filters",
		"/v2/procurement/filters",
		"/v2/procurement/tenders",
	}
	detailPathPatterns = []*regexp.Regexp{
		regexp.MustCompile(`^/v1/beneficial-ownership/detail/[A-Z0-9]+$`),
		regexp.MustCompile(`^/v2/procurement/tenders/[^/]+$`),
	}
)

// Known good bot patterns with their verification domains
var goodBotPatterns = map[string]goodBotConfig{
	"Googlebot": {
		userAgentPattern: regexp.MustCompile(`(?i)googlebot`),
		verifyDomains:    []string{"googlebot.com", "google.com"},
	},
	"Bingbot": {
		userAgentPattern: regexp.MustCompile(`(?i)bingbot`),
		verifyDomains:    []string{"search.msn.com"},
	},
	"DuckDuckBot": {
		userAgentPattern: regexp.MustCompile(`(?i)duckduckbot`),
		verifyDomains:    []string{"duckduckgo.com"},
	},
	"Slurp": {
		userAgentPattern: regexp.MustCompile(`(?i)slurp`),
		verifyDomains:    []string{"crawl.yahoo.net"},
	},
	"Applebot": {
		userAgentPattern: regexp.MustCompile(`(?i)applebot`),
		verifyDomains:    []string{"applebot.apple.com"},
	},
}

type goodBotConfig struct {
	userAgentPattern *regexp.Regexp
	verifyDomains    []string
}

// suspiciousUAPattern holds a pattern and its confidence level.
// High confidence patterns are tools primarily used for scraping.
// Low confidence patterns are tools that may be used legitimately (API testing, CI/CD, etc.).
type suspiciousUAPattern struct {
	pattern    *regexp.Regexp
	confidence float64
}

// Suspicious User-Agent patterns with tiered confidence levels.
// High confidence (0.7-0.8): Known scraping frameworks rarely used for legitimate purposes.
// Low confidence (0.3): Tools commonly used for legitimate API testing, monitoring, and integrations.
// See issue #018 for rationale on reducing confidence for common development tools.
var suspiciousUAPatterns = []suspiciousUAPattern{
	// High confidence - primarily scraping tools
	{regexp.MustCompile(`(?i)^scrapy`), 0.8},          // Python scraping framework
	{regexp.MustCompile(`(?i)^python-requests`), 0.7}, // Often used for scraping
	{regexp.MustCompile(`(?i)^python-urllib`), 0.7},   // Often used for scraping
	{regexp.MustCompile(`(?i)^wget/`), 0.7},           // Automated downloads
	{regexp.MustCompile(`(?i)^libwww-perl`), 0.7},     // Perl scraping

	// Low confidence - commonly used for legitimate purposes
	// These patterns contribute less to the overall bot score to reduce false positives
	// from CI/CD pipelines, monitoring tools, and integration partners.
	{regexp.MustCompile(`(?i)^curl/`), 0.3},          // API testing, health checks
	{regexp.MustCompile(`(?i)^go-http-client`), 0.3}, // Go applications, microservices
	{regexp.MustCompile(`(?i)^java/`), 0.3},          // Java applications
	{regexp.MustCompile(`(?i)^okhttp`), 0.3},         // Android/Java HTTP client
	{regexp.MustCompile(`(?i)^axios`), 0.3},          // Node.js applications
	{regexp.MustCompile(`(?i)^node-fetch`), 0.3},     // Node.js applications
	{regexp.MustCompile(`(?i)^httpclient`), 0.3},     // Generic HTTP clients
	{regexp.MustCompile(`(?i)^php/`), 0.3},           // PHP applications
}

// botDetectionMiddleware creates middleware that detects and optionally blocks bots
func botDetectionMiddleware(redisClient *redis.Client, logger *slog.Logger, config BotDetectionConfig) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if !config.Enabled {
				next.ServeHTTP(w, r)
				return
			}

			// Skip health checks
			if isHealthCheckPath(r.URL.Path) {
				next.ServeHTTP(w, r)
				return
			}

			ctx := r.Context()
			ip := getRealIP(r)
			// Sanitize IP for Redis key construction to prevent key injection
			// Keep raw IP for logging and DNS verification (human-readable)
			safeIP := sanitizeIPForKey(ip)

			// Check if IP is already blocked (cached decision)
			if isIPBlockedWithLogging(ctx, redisClient, logger, safeIP) {
				logBotBlock(logger, r, ip, "cached_block", nil)
				http.Error(w, "Too Many Requests", http.StatusTooManyRequests)
				return
			}

			userAgent := r.Header.Get("User-Agent")

			// Check if this is a verified good bot
			// Use raw IP for DNS verification (needs actual IP for reverse lookup)
			if config.WhitelistGoodBots {
				if isGoodBot, botName := verifyGoodBot(userAgent, ip); isGoodBot {
					// Track but allow good bots
					logger.Debug("Good bot verified",
						"bot", botName,
						"ip", ip,
						"path", r.URL.Path,
					)
					next.ServeHTTP(w, r)
					return
				}
			}

			// Track request for behavioral analysis BEFORE detection
			// This ensures the current request is included in the analysis
			trackRequest(ctx, redisClient, safeIP, r.URL.Path, config.WindowDuration)

			// Run detection signals (now includes current request in counts)
			// Use safeIP for Redis operations, raw ip for logging
			result := runBotDetection(ctx, redisClient, logger, r, safeIP, userAgent, config)
			// Store raw IP in result for logging (human-readable)
			result.IP = ip

			// Log detection result for monitoring
			if result.TotalConfidence > 0.3 {
				logBotDetection(logger, r, result)
			}

			// Block if confidence exceeds threshold
			if result.IsBot && config.BlockBots {
				// Cache the block decision for 5 minutes to reduce Redis load
				cacheBlockDecision(ctx, redisClient, safeIP)
				logBotBlock(logger, r, ip, "detection", &result)
				http.Error(w, "Too Many Requests", http.StatusTooManyRequests)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// runBotDetection executes all detection signals and aggregates results using
// weighted confidence scoring.
//
// ## Why Weighted Scoring vs Binary Signals
//
// We use weighted confidence scoring rather than simple "N of M signals triggered"
// because different signals have different reliability levels:
//
//   - Search:Detail Ratio (35%): Hardest to fake while maintaining scraping efficiency.
//     A scraper that visits detail pages to blend in loses much of its speed advantage.
//     This is our most reliable behavioral indicator.
//
//   - Header Analysis (25%): Real browsers send consistent headers (Accept-Language,
//     Sec-Fetch-*, etc.). Missing headers strongly indicate automated clients, but
//     some legitimate clients may also omit headers.
//
//   - User-Agent (20%): Easy to spoof but catches lazy bots using default library UAs
//     like "python-requests" or "curl". Lower weight because sophisticated scrapers
//     simply fake realistic UAs.
//
//   - Request Rate (20%): High request rates indicate automation but legitimate
//     power users may also trigger this. Supplements ratio analysis.
//
// The 60% confidence threshold means no single signal can trigger a block on its own.
// This reduces false positives while still catching bots that exhibit multiple
// suspicious behaviors.
//
// See ADR-0015 (docs/adr/0015-bot-detection-middleware.md) for full rationale.
//
// ## Redis Pipeline Optimization
//
// This function batches all Redis read operations into a single pipeline,
// reducing network round-trips from 3 to 1. Before optimization, each detection
// required 3 sequential GETs (search count, detail count, request count).
// With pipelining, all 3 GETs are sent in a single request.
func runBotDetection(ctx context.Context, redisClient *redis.Client, logger *slog.Logger, r *http.Request, ip, userAgent string, config BotDetectionConfig) botDetectionResult {
	var signals []botSignal
	var totalConfidence float64

	// Signal 1: Missing or suspicious headers (no Redis needed)
	headerSignal := checkHeaders(r)
	signals = append(signals, headerSignal)
	if headerSignal.Triggered {
		totalConfidence += headerSignal.Confidence * headerAnalysisWeight
	}

	// Signal 2: Suspicious User-Agent (no Redis needed)
	uaSignal := checkUserAgent(userAgent)
	signals = append(signals, uaSignal)
	if uaSignal.Triggered {
		totalConfidence += uaSignal.Confidence * userAgentWeight
	}

	// Fetch all behavioral data from Redis in a single pipeline (1 round-trip instead of 3)
	searchKey := botDetectKeyPrefix + botDetectSearchCount + ip
	detailKey := botDetectKeyPrefix + botDetectDetailCount + ip
	requestKey := botDetectKeyPrefix + botDetectRequestCount + ip

	pipe := redisClient.Pipeline()
	searchCmd := pipe.Get(ctx, searchKey)
	detailCmd := pipe.Get(ctx, detailKey)
	requestCmd := pipe.Get(ctx, requestKey)
	if _, err := pipe.Exec(ctx); err != nil && err != redis.Nil {
		// Log pipeline errors but continue with zero counts (fail-open)
		logger.Debug("bot detection pipeline error", "error", err, "ip", ip)
	}

	// Extract counts from pipeline results (redis.Nil errors mean count is 0)
	searchCount, _ := searchCmd.Int64()
	detailCount, _ := detailCmd.Int64()
	requestCount, _ := requestCmd.Int64()

	// Signal 3: Search:Detail ratio (using pre-fetched counts)
	ratioSignal := checkSearchDetailRatioFromCounts(searchCount, detailCount, config.SearchDetailRatioThreshold)
	signals = append(signals, ratioSignal)
	if ratioSignal.Triggered {
		totalConfidence += ratioSignal.Confidence * searchDetailRatioWeight
	}

	// Signal 4: Request rate pattern (using pre-fetched count)
	rateSignal := checkRequestRateFromCount(requestCount, config.RequestsPerMinuteThreshold, config.WindowDuration)
	signals = append(signals, rateSignal)
	if rateSignal.Triggered {
		totalConfidence += rateSignal.Confidence * requestRateWeight
	}

	// Determine if bot based on total confidence
	isBot := totalConfidence >= confidenceThreshold

	return botDetectionResult{
		IsBot:           isBot,
		TotalConfidence: totalConfidence,
		Signals:         signals,
		IP:              ip,
		UserAgent:       userAgent,
	}
}

// checkHeaders analyzes HTTP headers for bot indicators
func checkHeaders(r *http.Request) botSignal {
	signal := botSignal{
		Name:       "header_analysis",
		Triggered:  false,
		Confidence: 0,
	}

	var issues []string

	// Check for missing Accept-Language (real browsers always send this)
	if r.Header.Get("Accept-Language") == "" {
		issues = append(issues, "missing Accept-Language")
		signal.Confidence += 0.3
	}

	// Check for missing Accept header
	if r.Header.Get("Accept") == "" {
		issues = append(issues, "missing Accept")
		signal.Confidence += 0.2
	}

	// Check for missing or generic Accept-Encoding
	acceptEncoding := r.Header.Get("Accept-Encoding")
	if acceptEncoding == "" {
		issues = append(issues, "missing Accept-Encoding")
		signal.Confidence += 0.2
	}

	// Check for missing Connection header (unusual for real browsers)
	if r.Header.Get("Connection") == "" && r.ProtoMajor == 1 {
		issues = append(issues, "missing Connection header")
		signal.Confidence += 0.1
	}

	// Check for suspicious header ordering or missing common headers
	// Real browsers send headers in consistent order
	if r.Header.Get("Sec-Fetch-Mode") == "" && r.Header.Get("Sec-Fetch-Site") == "" {
		// Modern browsers send Sec-Fetch-* headers
		// Their absence with a "modern" UA is suspicious
		if strings.Contains(r.Header.Get("User-Agent"), "Chrome") ||
			strings.Contains(r.Header.Get("User-Agent"), "Firefox") {
			issues = append(issues, "missing Sec-Fetch headers for modern browser UA")
			signal.Confidence += 0.3
		}
	}

	if signal.Confidence > 0 {
		signal.Triggered = true
		signal.Details = strings.Join(issues, "; ")
	}

	// Cap confidence at 1.0
	if signal.Confidence > 1.0 {
		signal.Confidence = 1.0
	}

	return signal
}

// checkUserAgent analyzes User-Agent for bot indicators.
// Uses tiered confidence levels: high confidence for known scraping tools,
// low confidence for tools commonly used in legitimate applications.
func checkUserAgent(userAgent string) botSignal {
	signal := botSignal{
		Name:       "user_agent_analysis",
		Triggered:  false,
		Confidence: 0,
	}

	// Empty User-Agent is highly suspicious
	if userAgent == "" {
		signal.Triggered = true
		signal.Confidence = 0.9
		signal.Details = "empty User-Agent"
		return signal
	}

	// Check against suspicious patterns with tiered confidence
	for _, uaPattern := range suspiciousUAPatterns {
		if uaPattern.pattern.MatchString(userAgent) {
			signal.Triggered = true
			signal.Confidence = uaPattern.confidence
			signal.Details = fmt.Sprintf("matches suspicious pattern: %s (confidence: %.1f)", uaPattern.pattern.String(), uaPattern.confidence)
			return signal
		}
	}

	// Check for unusually short User-Agent
	if len(userAgent) < 20 {
		signal.Triggered = true
		signal.Confidence = 0.5
		signal.Details = fmt.Sprintf("unusually short UA (%d chars)", len(userAgent))
		return signal
	}

	return signal
}

// checkSearchDetailRatio analyzes the ratio of search to detail requests.
// Redis errors are logged but do not block the request (fail-open behavior).
func checkSearchDetailRatio(ctx context.Context, redisClient *redis.Client, logger *slog.Logger, ip string, threshold float64) botSignal {
	signal := botSignal{
		Name:       "search_detail_ratio",
		Triggered:  false,
		Confidence: 0,
	}

	searchKey := botDetectKeyPrefix + botDetectSearchCount + ip
	detailKey := botDetectKeyPrefix + botDetectDetailCount + ip

	// Get counts from Redis (log errors but continue with fail-open behavior)
	searchCount, err := redisClient.Get(ctx, searchKey).Int64()
	if err != nil && err != redis.Nil {
		logger.Warn("bot detection redis error",
			"operation", "get",
			"key", searchKey,
			"error", err.Error(),
		)
	}
	detailCount, err := redisClient.Get(ctx, detailKey).Int64()
	if err != nil && err != redis.Nil {
		logger.Warn("bot detection redis error",
			"operation", "get",
			"key", detailKey,
			"error", err.Error(),
		)
	}

	// Need minimum search requests to evaluate
	if searchCount < 10 {
		return signal
	}

	// Calculate ratio (avoid division by zero)
	var ratio float64
	if detailCount == 0 {
		ratio = float64(searchCount) // Treat as infinite ratio
	} else {
		ratio = float64(searchCount) / float64(detailCount)
	}

	if ratio > threshold {
		signal.Triggered = true
		// Scale confidence based on how much threshold is exceeded
		signal.Confidence = min(1.0, ratio/threshold*0.7)
		signal.Details = fmt.Sprintf("ratio %.1f (search=%d, detail=%d, threshold=%.1f)",
			ratio, searchCount, detailCount, threshold)
	}

	return signal
}

// checkRequestRate analyzes request frequency patterns.
// Redis errors are logged but do not block the request (fail-open behavior).
func checkRequestRate(ctx context.Context, redisClient *redis.Client, logger *slog.Logger, ip string, threshold int, window time.Duration) botSignal {
	signal := botSignal{
		Name:       "request_rate",
		Triggered:  false,
		Confidence: 0,
	}

	key := botDetectKeyPrefix + botDetectRequestCount + ip

	// Get current count (log errors but continue with fail-open behavior)
	count, err := redisClient.Get(ctx, key).Int64()
	if err != nil && err != redis.Nil {
		logger.Warn("bot detection redis error",
			"operation", "get",
			"key", key,
			"error", err.Error(),
		)
	}

	// Calculate rate per minute
	windowMinutes := window.Minutes()
	if windowMinutes == 0 {
		windowMinutes = 1
	}
	ratePerMinute := float64(count) / windowMinutes

	if ratePerMinute > float64(threshold) {
		signal.Triggered = true
		// Scale confidence based on how much threshold is exceeded
		signal.Confidence = min(1.0, ratePerMinute/float64(threshold)*0.6)
		signal.Details = fmt.Sprintf("%.1f req/min (threshold=%d)", ratePerMinute, threshold)
	}

	return signal
}

// checkSearchDetailRatioFromCounts analyzes the ratio using pre-fetched counts.
// This is the pipeline-friendly version that doesn't make Redis calls.
func checkSearchDetailRatioFromCounts(searchCount, detailCount int64, threshold float64) botSignal {
	signal := botSignal{
		Name:       "search_detail_ratio",
		Triggered:  false,
		Confidence: 0,
	}

	// Need minimum search requests to evaluate
	if searchCount < 10 {
		return signal
	}

	// Calculate ratio (avoid division by zero)
	var ratio float64
	if detailCount == 0 {
		ratio = float64(searchCount) // Treat as infinite ratio
	} else {
		ratio = float64(searchCount) / float64(detailCount)
	}

	if ratio > threshold {
		signal.Triggered = true
		// Scale confidence based on how much threshold is exceeded
		signal.Confidence = min(1.0, ratio/threshold*0.7)
		signal.Details = fmt.Sprintf("ratio %.1f (search=%d, detail=%d, threshold=%.1f)",
			ratio, searchCount, detailCount, threshold)
	}

	return signal
}

// checkRequestRateFromCount analyzes request frequency using pre-fetched count.
// This is the pipeline-friendly version that doesn't make Redis calls.
func checkRequestRateFromCount(requestCount int64, threshold int, window time.Duration) botSignal {
	signal := botSignal{
		Name:       "request_rate",
		Triggered:  false,
		Confidence: 0,
	}

	// Calculate rate per minute
	windowMinutes := window.Minutes()
	if windowMinutes == 0 {
		windowMinutes = 1
	}
	ratePerMinute := float64(requestCount) / windowMinutes

	if ratePerMinute > float64(threshold) {
		signal.Triggered = true
		// Scale confidence based on how much threshold is exceeded
		signal.Confidence = min(1.0, ratePerMinute/float64(threshold)*0.6)
		signal.Details = fmt.Sprintf("%.1f req/min (threshold=%d)", ratePerMinute, threshold)
	}

	return signal
}

// trackRequest updates behavioral counters in Redis using atomic operations.
// Uses a Lua script to atomically increment and set TTL, preventing race conditions
// where keys could persist indefinitely if a crash occurs between INCR and EXPIRE.
// Errors are intentionally ignored (fail-open) to avoid blocking requests on Redis issues.
func trackRequest(ctx context.Context, redisClient *redis.Client, ip, path string, window time.Duration) {
	// Always increment total request count (atomic with TTL)
	// Error ignored: fail-open behavior - tracking failure shouldn't block requests
	requestKey := botDetectKeyPrefix + botDetectRequestCount + ip
	_, _ = atomicIncrWithTTL(ctx, redisClient, requestKey, window)

	// Check if this is a search path
	for _, searchPath := range searchPathPatterns {
		if strings.HasPrefix(path, searchPath) {
			searchKey := botDetectKeyPrefix + botDetectSearchCount + ip
			_, _ = atomicIncrWithTTL(ctx, redisClient, searchKey, window)
			return
		}
	}

	// Check if this is a detail path
	for _, detailPattern := range detailPathPatterns {
		if detailPattern.MatchString(path) {
			detailKey := botDetectKeyPrefix + botDetectDetailCount + ip
			_, _ = atomicIncrWithTTL(ctx, redisClient, detailKey, window)
			return
		}
	}
}

// verifyGoodBot checks if a claimed good bot is legitimate via reverse DNS
func verifyGoodBot(userAgent, ip string) (bool, string) {
	for botName, config := range goodBotPatterns {
		if config.userAgentPattern.MatchString(userAgent) {
			// Verify via reverse DNS
			if verifyBotDNS(ip, config.verifyDomains) {
				return true, botName
			}
			// Claims to be a good bot but DNS doesn't verify
			return false, ""
		}
	}
	return false, ""
}

// verifyBotDNS performs reverse DNS lookup to verify bot legitimacy.
// It uses a two-step verification process:
// 1. Reverse DNS lookup to get the hostname for the IP
// 2. Forward DNS lookup to confirm the hostname resolves back to the same IP
// This prevents DNS spoofing attacks where an attacker sets up a PTR record
// pointing to a legitimate domain but the domain doesn't actually resolve to their IP.
//
// Security: Uses in-memory caching (1 hour TTL) and 2-second timeout to prevent
// DoS attacks via repeated DNS lookups with fake Googlebot user agents.
func verifyBotDNS(ip string, allowedDomains []string) bool {
	// Check cache first
	if cached, ok := dnsVerificationCache.Load(ip); ok {
		entry := cached.(dnsCacheEntry)
		if time.Now().Before(entry.expiry) {
			return entry.verified
		}
		// Cache expired, delete and continue with lookup
		dnsVerificationCache.Delete(ip)
	}

	// Create context with timeout to prevent slow DNS from blocking
	ctx, cancel := context.WithTimeout(context.Background(), dnsLookupTimeout)
	defer cancel()

	// Perform verification with timeout
	verified := verifyBotDNSWithResolver(ctx, ip, allowedDomains, defaultDNSResolver)

	// Cache the result (both positive and negative results)
	dnsVerificationCache.Store(ip, dnsCacheEntry{
		verified: verified,
		expiry:   time.Now().Add(dnsCacheTTL),
	})

	return verified
}

// verifyBotDNSWithResolver performs DNS verification using a provided resolver.
// This allows for testing with mock DNS responses.
func verifyBotDNSWithResolver(ctx context.Context, ip string, allowedDomains []string, resolver DNSResolver) bool {
	// Perform reverse DNS lookup
	names, err := resolver.LookupAddr(ctx, ip)
	if err != nil || len(names) == 0 {
		return false
	}

	hostname := strings.TrimSuffix(names[0], ".")

	// Check if hostname ends with any allowed domain
	for _, domain := range allowedDomains {
		if strings.HasSuffix(hostname, domain) {
			// Forward lookup to verify (prevent DNS spoofing)
			addrs, err := resolver.LookupHost(ctx, hostname)
			if err != nil {
				return false
			}
			for _, addr := range addrs {
				if addr == ip {
					return true
				}
			}
		}
	}

	return false
}

// isIPBlocked checks if an IP is in the blocked cache.
// Note: This function does not log errors. Use isIPBlockedWithLogging in middleware.
func isIPBlocked(ctx context.Context, redisClient *redis.Client, ip string) bool {
	key := botDetectKeyPrefix + botDetectBlockedPrefix + ip
	exists, _ := redisClient.Exists(ctx, key).Result()
	return exists > 0
}

// isIPBlockedWithLogging checks if an IP is in the blocked cache with error logging.
// Redis errors are logged but return false (fail-open behavior).
func isIPBlockedWithLogging(ctx context.Context, redisClient *redis.Client, logger *slog.Logger, ip string) bool {
	key := botDetectKeyPrefix + botDetectBlockedPrefix + ip
	exists, err := redisClient.Exists(ctx, key).Result()
	if err != nil {
		logger.Warn("bot detection redis error",
			"operation", "exists",
			"key", key,
			"error", err.Error(),
		)
		// Fail-open: assume not blocked on Redis error
		return false
	}
	return exists > 0
}

// cacheBlockDecision caches a block decision to reduce Redis lookups.
func cacheBlockDecision(ctx context.Context, redisClient *redis.Client, ip string) {
	key := botDetectKeyPrefix + botDetectBlockedPrefix + ip
	redisClient.Set(ctx, key, "1", 5*time.Minute)
}

// getRealIP extracts the client IP from r.RemoteAddr.
// This function assumes Chi's middleware.RealIP has already been applied early in the
// middleware chain, which securely extracts the real client IP from X-Forwarded-For
// or X-Real-IP headers and rewrites r.RemoteAddr.
//
// SECURITY: We do NOT parse X-Forwarded-For or X-Real-IP headers here because they
// can be trivially spoofed by attackers. Chi's RealIP middleware handles this securely
// by only trusting the rightmost IP (added by our trusted reverse proxy).
func getRealIP(r *http.Request) string {
	// RemoteAddr has already been set to the real client IP by middleware.RealIP
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		// RemoteAddr might not have a port (e.g., in some test scenarios)
		return r.RemoteAddr
	}
	return ip
}

// sanitizeIPForKey validates and sanitizes an IP address for safe use in Redis keys.
// It ensures the IP is valid and converts it to a canonical form that is safe for
// Redis key construction (no colons, which Redis uses as key separator).
//
// Returns:
//   - For valid IPv4: the IP address as-is (e.g., "192.168.1.1")
//   - For valid IPv6: the IP address with colons replaced by underscores
//     (e.g., "2001:db8::1" becomes "2001_db8__1")
//   - For invalid/malformed IPs: "invalid"
//
// SECURITY: This function prevents Redis key injection by:
// 1. Validating that the input is a valid IP address
// 2. Using the canonical form from net.ParseIP (handles IPv6 normalization)
// 3. Replacing colons with underscores to avoid Redis key separator conflicts
func sanitizeIPForKey(ip string) string {
	parsed := net.ParseIP(ip)
	if parsed == nil {
		return "invalid"
	}
	// Use canonical form (handles IPv6 normalization)
	// Replace colons with underscores for Redis key safety
	// (colons are often used as key separators in Redis)
	return strings.ReplaceAll(parsed.String(), ":", "_")
}

// logBotDetection logs bot detection results
func logBotDetection(logger *slog.Logger, r *http.Request, result botDetectionResult) {
	signalsJSON, _ := json.Marshal(result.Signals)

	logger.Warn("bot detection triggered",
		"ip", result.IP,
		"user_agent", sanitizeLogValue(result.UserAgent),
		"path", sanitizeLogValue(r.URL.Path),
		"is_bot", result.IsBot,
		"confidence", result.TotalConfidence,
		"signals", string(signalsJSON),
	)
}

// logBotBlock logs when a bot is blocked
func logBotBlock(logger *slog.Logger, r *http.Request, ip, reason string, result *botDetectionResult) {
	attrs := []any{
		"ip", ip,
		"path", sanitizeLogValue(r.URL.Path),
		"reason", reason,
	}

	if result != nil {
		attrs = append(attrs,
			"confidence", result.TotalConfidence,
			"user_agent", sanitizeLogValue(result.UserAgent),
		)
	}

	logger.Warn("bot blocked", attrs...)
}
