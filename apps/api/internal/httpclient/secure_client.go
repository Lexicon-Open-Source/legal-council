package httpclient

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"strings"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

// Policy names the outbound HTTP posture at each call site.
type Policy string

const (
	// PolicyPublicOutbound is for public internet HTTP calls. Private,
	// loopback, link-local, and cloud metadata addresses are blocked.
	PolicyPublicOutbound Policy = "public_outbound"
	// PolicyInternalService is for first-party services on the deployment
	// network. Private RFC1918 addresses are allowed only behind an allowlisted
	// hostname; loopback, link-local, and metadata addresses stay blocked.
	PolicyInternalService Policy = "internal_service"
	// PolicyDevelopmentLocal is for localhost/private development workflows.
	// Metadata and link-local addresses stay blocked.
	PolicyDevelopmentLocal Policy = "development_local"
)

type clientPolicy struct {
	name                Policy
	allowedHosts        []allowedHost
	allowPrivateIPs     bool
	allowLoopbackIPs    bool
	requireAllowedHosts bool
}

type allowedHost struct {
	host    string
	port    string
	hasPort bool
}

type resolver interface {
	LookupHost(ctx context.Context, host string) ([]string, error)
}

type defaultResolver struct{}

func (defaultResolver) LookupHost(ctx context.Context, host string) ([]string, error) {
	return net.DefaultResolver.LookupHost(ctx, host)
}

type dialContextFunc func(ctx context.Context, network, addr string) (net.Conn, error)

type secureDialer struct {
	policy      clientPolicy
	resolver    resolver
	dialContext dialContextFunc
}

// NewClient creates an HTTP client with SSRF protection, DNS rebinding
// protection, and OpenTelemetry instrumentation.
func NewClient(timeout time.Duration, policy Policy, allowedHosts []string) (*http.Client, error) {
	clientPolicy, err := newClientPolicy(policy, allowedHosts)
	if err != nil {
		return nil, err
	}
	return newClient(timeout, clientPolicy, defaultResolver{}, nil), nil
}

// NewPublicOutboundClient creates a client for public internet calls.
func NewPublicOutboundClient(timeout time.Duration, allowedHosts []string) *http.Client {
	client, _ := NewClient(timeout, PolicyPublicOutbound, allowedHosts)
	return client
}

// NewInternalServiceClient creates a client for first-party private-network services.
func NewInternalServiceClient(timeout time.Duration, allowedHosts []string) (*http.Client, error) {
	return NewClient(timeout, PolicyInternalService, allowedHosts)
}

// NewDevelopmentLocalClient creates a client for local development services.
func NewDevelopmentLocalClient(timeout time.Duration, allowedHosts []string) *http.Client {
	client, _ := NewClient(timeout, PolicyDevelopmentLocal, allowedHosts)
	return client
}

// NewSecureClient creates an HTTP client with SSRF protection and OpenTelemetry instrumentation.
//
// Deprecated: use NewPublicOutboundClient, NewInternalServiceClient, or
// NewDevelopmentLocalClient so the call site names the outbound policy.
func NewSecureClient(timeout time.Duration, allowPrivateIPs bool, allowedHosts []string) *http.Client {
	policy := PolicyPublicOutbound
	if allowPrivateIPs {
		if len(allowedHosts) > 0 {
			policy = PolicyInternalService
		} else {
			policy = PolicyDevelopmentLocal
		}
	}
	client, err := NewClient(timeout, policy, allowedHosts)
	if err != nil {
		panic(err)
	}
	return client
}

func newClientPolicy(policy Policy, allowedHosts []string) (clientPolicy, error) {
	p := clientPolicy{name: policy, allowedHosts: parseAllowedHosts(allowedHosts)}
	switch policy {
	case PolicyPublicOutbound:
		return p, nil
	case PolicyInternalService:
		p.allowPrivateIPs = true
		p.requireAllowedHosts = true
	case PolicyDevelopmentLocal:
		p.allowPrivateIPs = true
		p.allowLoopbackIPs = true
	default:
		return clientPolicy{}, fmt.Errorf("unknown HTTP client policy: %s", policy)
	}

	if p.requireAllowedHosts && len(p.allowedHosts) == 0 {
		return clientPolicy{}, fmt.Errorf("%s policy requires at least one allowed host", policy)
	}

	return p, nil
}

func newClient(timeout time.Duration, policy clientPolicy, resolver resolver, dialContext dialContextFunc) *http.Client {
	dialer := secureDialer{
		policy:      policy,
		resolver:    resolver,
		dialContext: dialContext,
	}

	baseTransport := &http.Transport{
		DialContext:           dialer.DialContext,
		MaxIdleConns:          100,
		IdleConnTimeout:       90 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
	}

	// Wrap with OpenTelemetry for distributed tracing
	return &http.Client{
		Timeout:   timeout,
		Transport: otelhttp.NewTransport(baseTransport),
	}
}

func (d secureDialer) DialContext(ctx context.Context, network, addr string) (net.Conn, error) {
	host, port, err := net.SplitHostPort(addr)
	if err != nil {
		return nil, fmt.Errorf("invalid address: %w", err)
	}

	if len(d.policy.allowedHosts) > 0 && !hostAllowed(host, port, d.policy.allowedHosts) {
		return nil, fmt.Errorf("hostname not whitelisted: %s", host)
	}

	ips, err := d.resolveIPs(ctx, host)
	if err != nil {
		return nil, err
	}

	for _, resolvedIP := range ips {
		if err := d.validateResolvedIP(resolvedIP); err != nil {
			return nil, err
		}
	}

	if d.dialContext == nil {
		defaultDialer := &net.Dialer{
			Timeout:   5 * time.Second,
			KeepAlive: 30 * time.Second,
		}
		d.dialContext = defaultDialer.DialContext
	}

	var lastErr error
	for _, validIP := range ips {
		// Connect to the validated IP directly to prevent DNS rebinding (TOCTOU).
		conn, err := d.dialContext(ctx, network, net.JoinHostPort(validIP.String(), port))
		if err == nil {
			return conn, nil
		}
		lastErr = err
	}
	return nil, lastErr
}

func (d secureDialer) resolveIPs(ctx context.Context, host string) ([]net.IP, error) {
	if ip := net.ParseIP(host); ip != nil {
		return []net.IP{ip}, nil
	}

	addrs, err := d.resolver.LookupHost(ctx, host)
	if err != nil {
		return nil, fmt.Errorf("DNS resolution failed for %s: %w", host, err)
	}

	ips := make([]net.IP, 0, len(addrs))
	for _, a := range addrs {
		if parsed := net.ParseIP(a); parsed != nil {
			ips = append(ips, parsed)
		}
	}
	if len(ips) == 0 {
		return nil, fmt.Errorf("no valid IPs found for %s", host)
	}
	return ips, nil
}

func (d secureDialer) validateResolvedIP(ip net.IP) error {
	if isCloudMetadataIP(ip) {
		return fmt.Errorf("blocked request to cloud metadata endpoint: %s", ip.String())
	}
	if ip.IsLoopback() && !d.policy.allowLoopbackIPs {
		return fmt.Errorf("blocked request to private/loopback IP: %s", ip.String())
	}
	if ip.IsPrivate() && !d.policy.allowPrivateIPs {
		return fmt.Errorf("blocked request to private/loopback IP: %s", ip.String())
	}
	return nil
}

func parseAllowedHosts(hosts []string) []allowedHost {
	parsedHosts := make([]allowedHost, 0, len(hosts))
	for _, host := range hosts {
		host = strings.ToLower(strings.TrimSpace(host))
		if host == "" {
			continue
		}

		if allowedName, allowedPort, err := net.SplitHostPort(host); err == nil {
			allowedName = normalizeAllowedHostName(allowedName)
			if allowedName == "" || allowedPort == "" {
				continue
			}
			parsedHosts = append(parsedHosts, allowedHost{
				host:    allowedName,
				port:    allowedPort,
				hasPort: true,
			})
			continue
		}

		host = normalizeAllowedHostName(host)
		if host == "" {
			continue
		}
		parsedHosts = append(parsedHosts, allowedHost{host: host})
	}
	return parsedHosts
}

func normalizeAllowedHostName(host string) string {
	host = strings.ToLower(strings.TrimSpace(host))
	if strings.HasPrefix(host, "[") && strings.HasSuffix(host, "]") {
		return strings.TrimSuffix(strings.TrimPrefix(host, "["), "]")
	}
	return host
}

func hostAllowed(host, port string, allowedHosts []allowedHost) bool {
	host = normalizeAllowedHostName(host)
	for _, allowed := range allowedHosts {
		if allowed.host != host {
			continue
		}
		if !allowed.hasPort || allowed.port == port {
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
