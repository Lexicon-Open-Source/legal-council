package i18n

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"sort"
	"testing"

	"github.com/BurntSushi/toml"
)

// --- T() tests ---

func TestT_Indonesian_Default(t *testing.T) {
	ctx := context.Background() // no localizer → falls back to Indonesian
	got := T(ctx, MsgErrorInvalidPage)
	if got != "Nomor halaman harus antara 1 dan 1.000." {
		t.Errorf("expected Indonesian translation, got %q", got)
	}
}

func TestT_English(t *testing.T) {
	ctx := WithLocalizer(context.Background(), NewLocalizer("en"), "en")
	got := T(ctx, MsgErrorInvalidPage)
	if got != "Page number must be between 1 and 1,000." {
		t.Errorf("expected English translation, got %q", got)
	}
}

func TestT_TemplateData(t *testing.T) {
	ctx := WithLocalizer(context.Background(), NewLocalizer("en"), "en")
	got := T(ctx, MsgErrorProcurementParamTooLong, map[string]any{"Param": "Agency"})
	want := "The Agency value is too long (maximum 500 characters)."
	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestT_FallbackToKeyOnMissing(t *testing.T) {
	ctx := context.Background()
	got := T(ctx, "nonexistent_key_xyz")
	if got != "nonexistent_key_xyz" {
		t.Errorf("expected raw key fallback, got %q", got)
	}
}

// --- FromCtx / LangFromCtx tests ---

func TestFromCtx_WithoutMiddleware(t *testing.T) {
	ctx := context.Background()
	localizer := FromCtx(ctx)
	if localizer == nil {
		t.Fatal("expected non-nil localizer fallback")
	}
	// FromCtx without middleware should produce Indonesian (default).
	// Verify by translating via T() which uses FromCtx internally.
	got := T(ctx, MsgGoods)
	if got != "Barang" {
		t.Errorf("expected Indonesian 'Barang', got %q", got)
	}
}

func TestLangFromCtx_WithoutMiddleware(t *testing.T) {
	ctx := context.Background()
	if lang := LangFromCtx(ctx); lang != "id" {
		t.Errorf("expected 'id', got %q", lang)
	}
}

func TestLangFromCtx_WithMiddleware(t *testing.T) {
	ctx := WithLocalizer(context.Background(), NewLocalizer("en"), "en")
	if lang := LangFromCtx(ctx); lang != "en" {
		t.Errorf("expected 'en', got %q", lang)
	}
}

// --- LanguageMiddleware tests ---

func TestLanguageMiddleware_English(t *testing.T) {
	var capturedLang string
	handler := LanguageMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedLang = LangFromCtx(r.Context())
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")
	handler.ServeHTTP(httptest.NewRecorder(), req)

	if capturedLang != "en" {
		t.Errorf("expected 'en', got %q", capturedLang)
	}
}

func TestLanguageMiddleware_Indonesian(t *testing.T) {
	var capturedLang string
	handler := LanguageMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedLang = LangFromCtx(r.Context())
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Accept-Language", "id-ID,id;q=0.9")
	handler.ServeHTTP(httptest.NewRecorder(), req)

	if capturedLang != "id" {
		t.Errorf("expected 'id', got %q", capturedLang)
	}
}

func TestLanguageMiddleware_MissingHeader(t *testing.T) {
	var capturedLang string
	handler := LanguageMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedLang = LangFromCtx(r.Context())
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	// No Accept-Language header
	handler.ServeHTTP(httptest.NewRecorder(), req)

	if capturedLang != "id" {
		t.Errorf("expected 'id' default, got %q", capturedLang)
	}
}

func TestLanguageMiddleware_MalformedHeader(t *testing.T) {
	var capturedLang string
	handler := LanguageMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedLang = LangFromCtx(r.Context())
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Accept-Language", "not-a-valid-language-tag-!!!!")
	handler.ServeHTTP(httptest.NewRecorder(), req)

	if capturedLang != "id" {
		t.Errorf("expected 'id' fallback for malformed header, got %q", capturedLang)
	}
}

func TestLanguageMiddleware_UnsupportedLanguage(t *testing.T) {
	var capturedLang string
	handler := LanguageMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedLang = LangFromCtx(r.Context())
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Accept-Language", "fr-FR,fr;q=0.9")
	handler.ServeHTTP(httptest.NewRecorder(), req)

	if capturedLang != "id" {
		t.Errorf("expected 'id' fallback for unsupported language, got %q", capturedLang)
	}
}

// --- TOML key parity test ---

func TestTOMLKeyParity(t *testing.T) {
	enKeys := loadTOMLKeys(t, "locales/en.toml")
	idKeys := loadTOMLKeys(t, "locales/id.toml")

	// Check en keys missing from id
	for _, k := range enKeys {
		if !contains(idKeys, k) {
			t.Errorf("key %q in en.toml but missing from id.toml", k)
		}
	}

	// Check id keys missing from en
	for _, k := range idKeys {
		if !contains(enKeys, k) {
			t.Errorf("key %q in id.toml but missing from en.toml", k)
		}
	}
}

func loadTOMLKeys(t *testing.T, path string) []string {
	t.Helper()
	// Read from the embedded filesystem
	data, err := localeFS.ReadFile(path)
	if err != nil {
		// Fall back to reading from disk (for development)
		absPath := filepath.Join("locales", filepath.Base(path))
		data, err = os.ReadFile(absPath)
		if err != nil {
			t.Fatalf("failed to read %s: %v", path, err)
		}
	}

	var raw map[string]any
	if err := toml.Unmarshal(data, &raw); err != nil {
		t.Fatalf("failed to parse %s: %v", path, err)
	}

	keys := make([]string, 0, len(raw))
	for k := range raw {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
