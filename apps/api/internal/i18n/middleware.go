package i18n

import (
	"net/http"

	"golang.org/x/text/language"
)

// supported lists the languages we support, in preference order.
// Indonesian is the default (index 0 of the matcher).
var supported = []language.Tag{
	language.Indonesian, // id — default
	language.English,    // en
}

var matcher = language.NewMatcher(supported)

// LanguageMiddleware parses the Accept-Language header, creates a Localizer,
// and stores both the localizer and language code in the request context.
//
// If the header is missing or unparseable, defaults to Indonesian.
// Bot detection middleware is unaffected — it reads the raw header, not context.
func LanguageMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		lang := "id" // default

		if accept := r.Header.Get("Accept-Language"); accept != "" {
			tags, _, err := language.ParseAcceptLanguage(accept)
			if err == nil && len(tags) > 0 {
				_, idx, _ := matcher.Match(tags...)
				if idx < len(supported) {
					base, _ := supported[idx].Base()
					lang = base.String()
				}
			}
		}

		localizer := NewLocalizer(lang)
		ctx := WithLocalizer(r.Context(), localizer, lang)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}
