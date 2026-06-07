// Package i18n provides internationalization for the Lexicon backend.
//
// It wraps nicksnyder/go-i18n v2 with embedded TOML translation files,
// middleware-based language detection, and a simple T() helper for handlers.
//
// Supported languages: Indonesian (id, default) and English (en).
package i18n

import (
	"context"
	"embed"

	"github.com/BurntSushi/toml"
	"github.com/nicksnyder/go-i18n/v2/i18n"
	"golang.org/x/text/language"
)

//go:embed locales/*.toml
var localeFS embed.FS

var bundle *i18n.Bundle

func init() {
	bundle = i18n.NewBundle(language.Indonesian)
	bundle.RegisterUnmarshalFunc("toml", toml.Unmarshal)
	// Load Indonesian first (default/fallback), then English.
	mustLoadMessageFile("locales/id.toml")
	mustLoadMessageFile("locales/en.toml")
}

func mustLoadMessageFile(path string) {
	if _, err := bundle.LoadMessageFileFS(localeFS, path); err != nil {
		panic("i18n: failed to load " + path + ": " + err.Error())
	}
}

// Context keys for storing localizer and language string.
type localizerCtxKey struct{}
type langCtxKey struct{}

// WithLocalizer stores a Localizer and language code in the context.
func WithLocalizer(ctx context.Context, localizer *i18n.Localizer, lang string) context.Context {
	ctx = context.WithValue(ctx, localizerCtxKey{}, localizer)
	ctx = context.WithValue(ctx, langCtxKey{}, lang)
	return ctx
}

// NewLocalizer creates a Localizer for the given language tag.
func NewLocalizer(lang string) *i18n.Localizer {
	return i18n.NewLocalizer(bundle, lang)
}

// FromCtx returns the Localizer stored in the request context.
// Falls back to Indonesian if no localizer is found.
func FromCtx(ctx context.Context) *i18n.Localizer {
	if l, ok := ctx.Value(localizerCtxKey{}).(*i18n.Localizer); ok {
		return l
	}
	return i18n.NewLocalizer(bundle, "id")
}

// LangFromCtx returns the language code ("en" or "id") from context.
// Used for language-keyed cache keys.
func LangFromCtx(ctx context.Context) string {
	if lang, ok := ctx.Value(langCtxKey{}).(string); ok {
		return lang
	}
	return "id"
}

// T translates a message ID using the localizer from context.
// Returns the raw message ID if translation fails (preserves current fallback behavior).
//
// Usage:
//
//	i18n.T(ctx, i18n.MsgErrorInvalidPage)
//	i18n.T(ctx, i18n.MsgConclusionSummary, map[string]any{"Total": "42", "Active": "10"})
func T(ctx context.Context, messageID string, templateData ...map[string]any) string {
	localizer := FromCtx(ctx)
	cfg := &i18n.LocalizeConfig{MessageID: messageID}
	if len(templateData) > 0 {
		cfg.TemplateData = templateData[0]
	}
	msg, err := localizer.Localize(cfg)
	if err != nil || msg == "" {
		return messageID
	}
	return msg
}
