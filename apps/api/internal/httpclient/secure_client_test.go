package httpclient

import (
	"context"
	"errors"
	"io"
	"net"
	"strings"
	"testing"
	"time"
)

func TestPublicOutboundPolicyRejectsPrivateLoopbackAndMetadataIPs(t *testing.T) {
	t.Parallel()

	policy, err := newClientPolicy(PolicyPublicOutbound, nil)
	if err != nil {
		t.Fatalf("new policy: %v", err)
	}

	tests := []struct {
		name        string
		addr        string
		wantMessage string
	}{
		{
			name:        "private ip",
			addr:        "10.0.1.126:80",
			wantMessage: "blocked request to private/loopback IP: 10.0.1.126",
		},
		{
			name:        "loopback ip",
			addr:        "127.0.0.1:80",
			wantMessage: "blocked request to private/loopback IP: 127.0.0.1",
		},
		{
			name:        "cloud metadata ip",
			addr:        "169.254.169.254:80",
			wantMessage: "blocked request to cloud metadata endpoint: 169.254.169.254",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			dialer := testSecureDialer(policy, fakeResolver{}, nil)
			_, err := dialer.DialContext(context.Background(), "tcp", tt.addr)
			if err == nil {
				t.Fatal("expected dial to fail")
			}
			if !strings.Contains(err.Error(), tt.wantMessage) {
				t.Fatalf("error = %q, want %q", err.Error(), tt.wantMessage)
			}
		})
	}
}

func TestPublicOutboundPolicyRejectsAllowlistedHostResolvingToPrivateIP(t *testing.T) {
	t.Parallel()

	policy, err := newClientPolicy(PolicyPublicOutbound, []string{"llm.lexicon.id"})
	if err != nil {
		t.Fatalf("new policy: %v", err)
	}
	dialer := testSecureDialer(policy, fakeResolver{"llm.lexicon.id": []string{"10.0.1.126"}}, nil)

	_, err = dialer.DialContext(context.Background(), "tcp", "llm.lexicon.id:443")
	if err == nil {
		t.Fatal("expected public outbound private IP resolution to fail")
	}
	if !strings.Contains(err.Error(), "blocked request to private/loopback IP: 10.0.1.126") {
		t.Fatalf("error = %q", err.Error())
	}
}

func TestInternalServicePolicyAllowsPrivateIPForAllowlistedHost(t *testing.T) {
	t.Parallel()

	policy, err := newClientPolicy(PolicyInternalService, []string{"llm", "llm:8001"})
	if err != nil {
		t.Fatalf("new policy: %v", err)
	}

	var dialedAddr string
	dialer := testSecureDialer(
		policy,
		fakeResolver{"llm": []string{"10.0.1.126"}},
		func(ctx context.Context, network, addr string) (net.Conn, error) {
			dialedAddr = addr
			return stubConn{}, nil
		},
	)

	conn, err := dialer.DialContext(context.Background(), "tcp", "llm:8001")
	if err != nil {
		t.Fatalf("expected internal private IP dial to succeed, got %v", err)
	}
	_ = conn.Close()

	if dialedAddr != "10.0.1.126:8001" {
		t.Fatalf("dialed address = %q, want validated private IP", dialedAddr)
	}
}

func TestHostAllowedUsesParsedAllowlist(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name         string
		allowedHosts []string
		host         string
		port         string
		want         bool
	}{
		{
			name:         "host with matching port",
			allowedHosts: []string{"llm:8001"},
			host:         "llm",
			port:         "8001",
			want:         true,
		},
		{
			name:         "host with different port",
			allowedHosts: []string{"llm:8001"},
			host:         "llm",
			port:         "8002",
			want:         false,
		},
		{
			name:         "host without port allows any port",
			allowedHosts: []string{"llm"},
			host:         "llm",
			port:         "8002",
			want:         true,
		},
		{
			name:         "bracketed ipv6 with matching port",
			allowedHosts: []string{"[2001:db8::1]:443"},
			host:         "2001:db8::1",
			port:         "443",
			want:         true,
		},
		{
			name:         "bracketed ipv6 with different port",
			allowedHosts: []string{"[2001:db8::1]:443"},
			host:         "2001:db8::1",
			port:         "80",
			want:         false,
		},
		{
			name:         "ipv6 without port allows any port",
			allowedHosts: []string{"2001:db8::1"},
			host:         "2001:db8::1",
			port:         "80",
			want:         true,
		},
		{
			name:         "bracketed ipv6 without port allows any port",
			allowedHosts: []string{"[2001:db8::1]"},
			host:         "2001:db8::1",
			port:         "80",
			want:         true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			if got := hostAllowed(tt.host, tt.port, parseAllowedHosts(tt.allowedHosts)); got != tt.want {
				t.Fatalf("hostAllowed() = %t, want %t", got, tt.want)
			}
		})
	}
}

func TestInternalServicePolicyRequiresAllowedHosts(t *testing.T) {
	t.Parallel()

	_, err := NewInternalServiceClient(time.Second, nil)
	if err == nil {
		t.Fatal("expected missing allowlist to fail")
	}
	if !strings.Contains(err.Error(), "internal_service policy requires at least one allowed host") {
		t.Fatalf("error = %q", err.Error())
	}
}

func TestInternalServicePolicyRejectsRawPrivateIPDespitePrivateAccess(t *testing.T) {
	t.Parallel()

	policy, err := newClientPolicy(PolicyInternalService, []string{"llm"})
	if err != nil {
		t.Fatalf("new policy: %v", err)
	}
	dialer := testSecureDialer(policy, fakeResolver{}, nil)

	_, err = dialer.DialContext(context.Background(), "tcp", "10.0.1.126:8001")
	if err == nil {
		t.Fatal("expected raw private IP to fail allowlist validation")
	}
	if !strings.Contains(err.Error(), "hostname not whitelisted: 10.0.1.126") {
		t.Fatalf("error = %q", err.Error())
	}
}

func TestInternalServicePolicyRejectsMetadataEndpoint(t *testing.T) {
	t.Parallel()

	policy, err := newClientPolicy(PolicyInternalService, []string{"llm"})
	if err != nil {
		t.Fatalf("new policy: %v", err)
	}
	dialer := testSecureDialer(policy, fakeResolver{"llm": []string{"169.254.169.254"}}, nil)

	_, err = dialer.DialContext(context.Background(), "tcp", "llm:8001")
	if err == nil {
		t.Fatal("expected metadata endpoint to fail")
	}
	if !strings.Contains(err.Error(), "blocked request to cloud metadata endpoint: 169.254.169.254") {
		t.Fatalf("error = %q", err.Error())
	}
}

func TestHostnameAllowlistMismatchReturnsClearError(t *testing.T) {
	t.Parallel()

	policy, err := newClientPolicy(PolicyPublicOutbound, []string{"api.example.com"})
	if err != nil {
		t.Fatalf("new policy: %v", err)
	}
	dialer := testSecureDialer(policy, fakeResolver{"evil.example.com": []string{"93.184.216.34"}}, nil)

	_, err = dialer.DialContext(context.Background(), "tcp", "evil.example.com:443")
	if err == nil {
		t.Fatal("expected hostname allowlist mismatch")
	}
	if !strings.Contains(err.Error(), "hostname not whitelisted: evil.example.com") {
		t.Fatalf("error = %q", err.Error())
	}
}

func TestDNSResolutionFailureReturnsClearError(t *testing.T) {
	t.Parallel()

	policy, err := newClientPolicy(PolicyPublicOutbound, nil)
	if err != nil {
		t.Fatalf("new policy: %v", err)
	}
	dialer := testSecureDialer(policy, fakeResolver{}, nil)

	_, err = dialer.DialContext(context.Background(), "tcp", "missing.example.com:443")
	if err == nil {
		t.Fatal("expected DNS failure")
	}
	if !strings.Contains(err.Error(), "DNS resolution failed for missing.example.com") {
		t.Fatalf("error = %q", err.Error())
	}
}

func TestDialContextReturnsLastDialError(t *testing.T) {
	t.Parallel()

	policy, err := newClientPolicy(PolicyPublicOutbound, nil)
	if err != nil {
		t.Fatalf("new policy: %v", err)
	}
	wantErr := errors.New("dial failed")
	dialer := testSecureDialer(
		policy,
		fakeResolver{"example.com": []string{"93.184.216.34"}},
		func(ctx context.Context, network, addr string) (net.Conn, error) {
			return nil, wantErr
		},
	)

	_, err = dialer.DialContext(context.Background(), "tcp", "example.com:443")
	if !errors.Is(err, wantErr) {
		t.Fatalf("error = %v, want %v", err, wantErr)
	}
}

func testSecureDialer(policy clientPolicy, resolver resolver, dialContext dialContextFunc) secureDialer {
	if dialContext == nil {
		dialContext = func(ctx context.Context, network, addr string) (net.Conn, error) {
			return nil, errors.New("dial should not be reached")
		}
	}
	return secureDialer{
		policy:      policy,
		resolver:    resolver,
		dialContext: dialContext,
	}
}

type fakeResolver map[string][]string

func (r fakeResolver) LookupHost(ctx context.Context, host string) ([]string, error) {
	if addrs, ok := r[host]; ok {
		return addrs, nil
	}
	return nil, &net.DNSError{Err: "no such host", Name: host}
}

type stubConn struct{}

func (stubConn) Read(b []byte) (int, error)         { return 0, io.EOF }
func (stubConn) Write(b []byte) (int, error)        { return len(b), nil }
func (stubConn) Close() error                       { return nil }
func (stubConn) LocalAddr() net.Addr                { return stubAddr("local") }
func (stubConn) RemoteAddr() net.Addr               { return stubAddr("remote") }
func (stubConn) SetDeadline(t time.Time) error      { return nil }
func (stubConn) SetReadDeadline(t time.Time) error  { return nil }
func (stubConn) SetWriteDeadline(t time.Time) error { return nil }

type stubAddr string

func (a stubAddr) Network() string { return string(a) }
func (a stubAddr) String() string  { return string(a) }
