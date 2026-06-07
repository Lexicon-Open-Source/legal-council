package config

import (
	"encoding/base64"
	"strings"
	"testing"
)

func TestLoadCMSUploadDefaults(t *testing.T) {
	setRequiredEnv(t)

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected config to load, got %v", err)
	}
	if cfg.S3PresignExpiry.String() != "15m0s" {
		t.Fatalf("expected default presign expiry to be 15m, got %s", cfg.S3PresignExpiry)
	}
	if cfg.CMSMaxImageSize != 10485760 {
		t.Fatalf("expected default image size 10485760, got %d", cfg.CMSMaxImageSize)
	}
	expectedDocTypes := "application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-powerpoint,application/vnd.openxmlformats-officedocument.presentationml.presentation,text/csv,text/plain,application/zip"
	if cfg.CMSAllowedDocumentTypes != expectedDocTypes {
		t.Fatalf("unexpected document types %q", cfg.CMSAllowedDocumentTypes)
	}
	if cfg.CMSFrontendBaseURL != "https://lexicon.id" {
		t.Fatalf("expected default CMS frontend base URL, got %q", cfg.CMSFrontendBaseURL)
	}
}

func TestLoadAcceptsCMSFrontendBaseURL(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("CMS_FRONTEND_BASE_URL", "https://staging.lexicon.id/")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected valid CMS frontend base URL to load, got %v", err)
	}
	if cfg.CMSFrontendBaseURL != "https://staging.lexicon.id" {
		t.Fatalf("expected normalized CMS frontend base URL, got %q", cfg.CMSFrontendBaseURL)
	}
}

func TestLoadRejectsInvalidCMSFrontendBaseURL(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("CMS_FRONTEND_BASE_URL", "://bad-url")

	_, err := Load()
	if err == nil {
		t.Fatal("expected invalid CMS frontend base URL to fail")
	}
	if !strings.Contains(err.Error(), "CMS_FRONTEND_BASE_URL") {
		t.Fatalf("expected CMS_FRONTEND_BASE_URL error, got %v", err)
	}
}

func TestLoadRejectsInvalidS3PublicBaseURL(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("S3_PUBLIC_BASE_URL", "://bad-url")

	_, err := Load()
	if err == nil {
		t.Fatal("expected invalid S3 public base URL to fail")
	}
}

func TestLoadRequiresBFFFieldsWhenAdminClientSecretSet(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("AUTHN_ADMIN_ISSUER", "https://auth.example.com/application/o/lexicon-admin/")
	t.Setenv("AUTHN_ADMIN_CLIENT_ID", "lexicon-admin")
	t.Setenv("AUTHN_ADMIN_CLIENT_SECRET", "super-secret")

	_, err := Load()
	if err == nil {
		t.Fatal("expected missing BFF fields to fail")
	}
}

func TestLoadRejectsInvalidAdminSessionEncryptionKey(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("AUTHN_ADMIN_ISSUER", "https://auth.example.com/application/o/lexicon-admin/")
	t.Setenv("AUTHN_ADMIN_CLIENT_ID", "lexicon-admin")
	t.Setenv("AUTHN_ADMIN_CLIENT_SECRET", "super-secret")
	t.Setenv("AUTHN_ADMIN_REDIRECT_URL", "http://localhost:8000/v1/admin/auth/callback")
	t.Setenv("ADMIN_DASHBOARD_URL", "http://localhost:3000/admin")
	t.Setenv("ADMIN_SESSION_ENCRYPTION_KEY", "not-base64")

	_, err := Load()
	if err == nil {
		t.Fatal("expected invalid admin session encryption key to fail")
	}
}

func TestLoadAcceptsValidBFFConfiguration(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("AUTHN_ADMIN_ISSUER", "https://auth.example.com/application/o/lexicon-admin/")
	t.Setenv("AUTHN_ADMIN_CLIENT_ID", "lexicon-admin")
	t.Setenv("AUTHN_ADMIN_CLIENT_SECRET", "super-secret")
	t.Setenv("AUTHN_ADMIN_REDIRECT_URL", "http://localhost:8000/v1/admin/auth/callback")
	t.Setenv("ADMIN_DASHBOARD_URL", "http://localhost:3000/admin")
	t.Setenv("ADMIN_SESSION_ENCRYPTION_KEY", base64.StdEncoding.EncodeToString(make([]byte, 32)))
	t.Setenv("ADMIN_SESSION_TTL", "24h")
	t.Setenv("ADMIN_SESSION_REFRESH_LEEWAY", "120s")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected valid BFF config to load, got %v", err)
	}
	if cfg.AdminSessionTTL.String() != "24h0m0s" {
		t.Fatalf("expected default-ish admin session TTL, got %s", cfg.AdminSessionTTL)
	}
	if cfg.AdminSessionRefreshLeeway.String() != "2m0s" {
		t.Fatalf("expected refresh leeway 2m, got %s", cfg.AdminSessionRefreshLeeway)
	}
}

func TestLoadAdminCookieDomainValidation(t *testing.T) {
	tests := []struct {
		name            string
		adminBFFEnabled bool
		cookieDomain    string
		redirectURL     string
		dashboardURL    string
		wantDomain      string
		wantErrContains string
	}{
		{
			name:            "parent domain covers API and dashboard subdomains",
			adminBFFEnabled: true,
			cookieDomain:    "lexicon.id",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantDomain:      "lexicon.id",
		},
		{
			name:            "leading dot parent domain is accepted and normalized",
			adminBFFEnabled: true,
			cookieDomain:    ".lexicon.id",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantDomain:      "lexicon.id",
		},
		{
			name:            "uppercase parent domain is accepted and lowercased",
			adminBFFEnabled: true,
			cookieDomain:    "Lexicon.ID",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantDomain:      "lexicon.id",
		},
		{
			name:            "parent domain may equal dashboard host",
			adminBFFEnabled: true,
			cookieDomain:    "lexicon.id",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://lexicon.id/",
			wantDomain:      "lexicon.id",
		},
		{
			name:            "empty domain is allowed when URL hostnames match",
			adminBFFEnabled: true,
			redirectURL:     "http://localhost:8000/v1/admin/auth/callback",
			dashboardURL:    "http://localhost:3000/admin",
		},
		{
			name: "empty domain is ignored when admin BFF mode is disabled",
		},
		{
			name:            "domain must cover redirect host",
			adminBFFEnabled: true,
			cookieDomain:    "evil.example",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantErrContains: "ADMIN_COOKIE_DOMAIN",
		},
		{
			name:            "domain rejects public suffix",
			adminBFFEnabled: true,
			cookieDomain:    "id",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantErrContains: "ADMIN_COOKIE_DOMAIN",
		},
		{
			name:            "domain rejects multi-label ICANN public suffix (co.uk)",
			adminBFFEnabled: true,
			cookieDomain:    "co.uk",
			redirectURL:     "https://api.co.uk/v1/admin/auth/callback",
			dashboardURL:    "https://admin.co.uk/",
			wantErrContains: "ADMIN_COOKIE_DOMAIN",
		},
		{
			name:            "domain rejects private (non-ICANN) public suffix (github.io)",
			adminBFFEnabled: true,
			cookieDomain:    "github.io",
			redirectURL:     "https://api.github.io/v1/admin/auth/callback",
			dashboardURL:    "https://admin.github.io/",
			wantErrContains: "ADMIN_COOKIE_DOMAIN",
		},
		{
			name:            "domain rejects label longer than 63 chars",
			adminBFFEnabled: true,
			cookieDomain:    strings.Repeat("a", 64) + ".id",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantErrContains: "ADMIN_COOKIE_DOMAIN",
		},
		{
			name:            "domain rejects label that starts with a hyphen",
			adminBFFEnabled: true,
			cookieDomain:    "-lexicon.id",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantErrContains: "ADMIN_COOKIE_DOMAIN",
		},
		{
			name:            "domain rejects punycode IDN that does not cover host",
			adminBFFEnabled: true,
			cookieDomain:    "xn--lexicn-foo.id",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantErrContains: "ADMIN_COOKIE_DOMAIN",
		},
		{
			name:            "domain rejects scheme",
			adminBFFEnabled: true,
			cookieDomain:    "https://lexicon.id",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantErrContains: "ADMIN_COOKIE_DOMAIN",
		},
		{
			name:            "domain rejects port",
			adminBFFEnabled: true,
			cookieDomain:    "lexicon.id:443",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantErrContains: "ADMIN_COOKIE_DOMAIN",
		},
		{
			name:            "domain rejects path",
			adminBFFEnabled: true,
			cookieDomain:    "lexicon.id/foo",
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantErrContains: "ADMIN_COOKIE_DOMAIN",
		},
		{
			name:            "domain is required when URL hostnames differ",
			adminBFFEnabled: true,
			redirectURL:     "https://api.lexicon.id/v1/admin/auth/callback",
			dashboardURL:    "https://admin.lexicon.id/",
			wantErrContains: "api.lexicon.id",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			setRequiredEnv(t)
			t.Setenv("ADMIN_COOKIE_DOMAIN", tt.cookieDomain)
			if tt.adminBFFEnabled {
				setAdminBFFEnv(t, tt.redirectURL, tt.dashboardURL)
			}

			cfg, err := Load()
			if tt.wantErrContains != "" {
				if err == nil {
					t.Fatalf("expected error containing %q", tt.wantErrContains)
				}
				if !strings.Contains(err.Error(), tt.wantErrContains) {
					t.Fatalf("expected error to contain %q, got %v", tt.wantErrContains, err)
				}
				return
			}
			if err != nil {
				t.Fatalf("expected config to load, got %v", err)
			}
			if cfg.AdminCookieDomain != tt.wantDomain {
				t.Fatalf("expected admin cookie domain %q, got %q", tt.wantDomain, cfg.AdminCookieDomain)
			}
		})
	}
}

func TestLoadRejectsInvalidIssuerInProduction(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("ENVIRONMENT", "production")
	t.Setenv("LLM_SERVICE_URL", "https://llm.lexicon.id")
	t.Setenv("CHATBOT_SERVICE_URL", "https://chatbot.lexicon.id")
	t.Setenv("AUTHN_ADMIN_ISSUER", "https://auth.example.invalid/application/o/lexicon-admin/")
	t.Setenv("AUTHN_ADMIN_CLIENT_ID", "lexicon-admin")

	_, err := Load()
	if err == nil {
		t.Fatal("expected .invalid issuer to fail in production")
	}
	if !strings.Contains(err.Error(), "AUTHN_ADMIN_ISSUER") {
		t.Fatalf("error = %q, want AUTHN_ADMIN_ISSUER guard", err.Error())
	}
}

func TestLoadLLMServiceURLClassification(t *testing.T) {
	tests := []struct {
		name          string
		environment   string
		llmServiceURL string
		wantClass     LLMServiceURLClass
		wantErr       string
	}{
		{
			name:          "production accepts internal service hostname",
			environment:   "production",
			llmServiceURL: "http://localhost:18001",
			wantClass:     LLMServiceURLInternalService,
		},
		{
			name:          "production rejects raw private ip",
			environment:   "production",
			llmServiceURL: "http://10.0.1.126:8001",
			wantErr:       "host not whitelisted",
		},
		{
			name:          "production accepts public hostname",
			environment:   "production",
			llmServiceURL: "https://llm.lexicon.id",
			wantClass:     LLMServiceURLPublicOutbound,
		},
		{
			name:          "production rejects unlisted host",
			environment:   "production",
			llmServiceURL: "https://evil.example.com",
			wantErr:       "host not whitelisted",
		},
		{
			name:          "development accepts localhost",
			environment:   "development",
			llmServiceURL: "http://localhost:8001",
			wantClass:     LLMServiceURLDevelopmentLocal,
		},
		{
			name:          "production rejects localhost",
			environment:   "production",
			llmServiceURL: "http://localhost:8001",
			wantErr:       "development-local LLM host not allowed in production",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			setRequiredEnv(t)
			t.Setenv("ENVIRONMENT", tt.environment)
			t.Setenv("LLM_SERVICE_URL", tt.llmServiceURL)
			if tt.environment == "production" {
				t.Setenv("CHATBOT_SERVICE_URL", "https://chatbot.lexicon.id")
			}

			class, classErr := ClassifyLLMServiceURL(tt.llmServiceURL, tt.environment)
			cfg, loadErr := Load()

			if tt.wantErr != "" {
				if classErr == nil {
					t.Fatalf("expected classification error containing %q", tt.wantErr)
				}
				if !strings.Contains(classErr.Error(), tt.wantErr) {
					t.Fatalf("classification error = %q, want %q", classErr.Error(), tt.wantErr)
				}
				if loadErr == nil {
					t.Fatalf("expected Load error containing %q", tt.wantErr)
				}
				if !strings.Contains(loadErr.Error(), tt.wantErr) {
					t.Fatalf("Load error = %q, want %q", loadErr.Error(), tt.wantErr)
				}
				return
			}

			if classErr != nil {
				t.Fatalf("expected classification to succeed, got %v", classErr)
			}
			if class != tt.wantClass {
				t.Fatalf("class = %q, want %q", class, tt.wantClass)
			}
			if loadErr != nil {
				t.Fatalf("expected Load to succeed, got %v", loadErr)
			}
			if cfg.LLMServiceURL != tt.llmServiceURL {
				t.Fatalf("LLMServiceURL = %q, want %q", cfg.LLMServiceURL, tt.llmServiceURL)
			}
		})
	}
}

func setRequiredEnv(t *testing.T) {
	t.Helper()

	t.Setenv("DATABASE_URL", "postgres://user:pass@localhost:5432/db?sslmode=disable")
	t.Setenv("REDIS_URL", "redis://localhost:6379/1")
	t.Setenv("LLM_SERVICE_URL", "http://localhost:8001")
	t.Setenv("LLM_API_KEY", "test-key")
	t.Setenv("CHATBOT_SERVICE_URL", "http://localhost:8001")
	t.Setenv("CHATBOT_API_KEY", "test-key")
	t.Setenv("ENVIRONMENT", "development")
}

func setAdminBFFEnv(t *testing.T, redirectURL, dashboardURL string) {
	t.Helper()

	t.Setenv("AUTHN_ADMIN_ISSUER", "https://auth.example.com/application/o/lexicon-admin/")
	t.Setenv("AUTHN_ADMIN_CLIENT_ID", "lexicon-admin")
	t.Setenv("AUTHN_ADMIN_CLIENT_SECRET", "super-secret")
	t.Setenv("AUTHN_ADMIN_REDIRECT_URL", redirectURL)
	t.Setenv("ADMIN_DASHBOARD_URL", dashboardURL)
	t.Setenv("ADMIN_SESSION_ENCRYPTION_KEY", base64.StdEncoding.EncodeToString(make([]byte, 32)))
}
