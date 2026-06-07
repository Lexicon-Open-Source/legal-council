// Fake Authentik for local E2E testing of the admin BFF auth feature.
// Serves OIDC discovery + JWKS + authorize + token + end_session. The
// token endpoint returns real RS256-signed JWTs so the backend's
// go-oidc verifier accepts them end-to-end.
//
// Run:   go run ./scripts/fake-authentik -addr :9999 -issuer http://localhost:9999 -client-id lexicon-admin
// Health:curl http://localhost:9999/.well-known/openid-configuration
package main

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/binary"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"sync"
	"time"
)

var (
	issuerFlag   = flag.String("issuer", "http://localhost:9999", "issuer base URL (absolute)")
	clientIDFlag = flag.String("client-id", "lexicon-admin", "expected client_id for ID-token audience claim")
	addrFlag     = flag.String("addr", ":9999", "listen address")

	mu          sync.Mutex
	codeToNonce = map[string]string{}
)

type oidcKey struct {
	priv *rsa.PrivateKey
	kid  string
}

var key *oidcKey

func main() {
	flag.Parse()

	priv, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		log.Fatalf("rsa gen: %v", err)
	}
	pub, err := x509.MarshalPKIXPublicKey(&priv.PublicKey)
	if err != nil {
		log.Fatalf("marshal pub: %v", err)
	}
	sum := sha256.Sum256(pub)
	kid := base64.RawURLEncoding.EncodeToString(sum[:8])
	key = &oidcKey{priv: priv, kid: kid}

	mux := http.NewServeMux()
	mux.HandleFunc("/.well-known/openid-configuration", discovery)
	mux.HandleFunc("/jwks", jwks)
	mux.HandleFunc("/authorize", authorize)
	mux.HandleFunc("/token", token)
	mux.HandleFunc("/logout", logout)
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "not found", http.StatusNotFound)
	})

	log.Printf("fake-authentik listening on %s (issuer=%s, client_id=%s, kid=%s)",
		*addrFlag, *issuerFlag, *clientIDFlag, kid)
	log.Fatal(http.ListenAndServe(*addrFlag, mux))
}

func discovery(w http.ResponseWriter, r *http.Request) {
	doc := map[string]any{
		"issuer":                                *issuerFlag,
		"authorization_endpoint":                *issuerFlag + "/authorize",
		"token_endpoint":                        *issuerFlag + "/token",
		"jwks_uri":                              *issuerFlag + "/jwks",
		"end_session_endpoint":                  *issuerFlag + "/logout",
		"id_token_signing_alg_values_supported": []string{"RS256"},
		"response_types_supported":              []string{"code"},
		"subject_types_supported":               []string{"public"},
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(doc)
}

func jwks(w http.ResponseWriter, r *http.Request) {
	pub := key.priv.PublicKey
	n := base64.RawURLEncoding.EncodeToString(pub.N.Bytes())
	eBytes := make([]byte, 4)
	binary.BigEndian.PutUint32(eBytes, uint32(pub.E))
	for len(eBytes) > 1 && eBytes[0] == 0 {
		eBytes = eBytes[1:]
	}
	e := base64.RawURLEncoding.EncodeToString(eBytes)
	doc := map[string]any{
		"keys": []map[string]any{{
			"kty": "RSA",
			"use": "sig",
			"alg": "RS256",
			"kid": key.kid,
			"n":   n,
			"e":   e,
		}},
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(doc)
}

// authorize captures the nonce against a fresh code and 302s the UA back
// to the redirect_uri with ?code=X&state=<original state>. Skips the
// real user-login UI and approves every request — this is a test harness.
func authorize(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	redirectURI := q.Get("redirect_uri")
	state := q.Get("state")
	nonce := q.Get("nonce")
	if redirectURI == "" || state == "" {
		http.Error(w, "missing redirect_uri or state", http.StatusBadRequest)
		return
	}

	code := randString(32)
	mu.Lock()
	codeToNonce[code] = nonce
	mu.Unlock()

	target, err := url.Parse(redirectURI)
	if err != nil {
		http.Error(w, "bad redirect_uri", http.StatusBadRequest)
		return
	}
	qs := target.Query()
	qs.Set("code", code)
	qs.Set("state", state)
	target.RawQuery = qs.Encode()
	http.Redirect(w, r, target.String(), http.StatusFound)
}

// token handles both authorization_code and refresh_token grants. The
// access token's `aud` claim is "lexicon-api" (not the client_id) to
// exercise the dedicated access-token verifier with SkipClientIDCheck.
func token(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		http.Error(w, "bad form", http.StatusBadRequest)
		return
	}
	grant := r.Form.Get("grant_type")
	now := time.Now()

	var nonce string
	switch grant {
	case "authorization_code":
		code := r.Form.Get("code")
		if code == "" {
			respondOAuthErr(w, "invalid_request", "missing code")
			return
		}
		mu.Lock()
		nonce = codeToNonce[code]
		delete(codeToNonce, code)
		mu.Unlock()
	case "refresh_token":
		if r.Form.Get("refresh_token") == "" {
			respondOAuthErr(w, "invalid_grant", "missing refresh_token")
			return
		}
	default:
		respondOAuthErr(w, "unsupported_grant_type", grant)
		return
	}

	idClaims := map[string]any{
		"iss":   *issuerFlag,
		"aud":   *clientIDFlag,
		"sub":   "user-e2e",
		"email": "admin@example.test",
		"iat":   now.Unix(),
		"exp":   now.Add(5 * time.Minute).Unix(),
	}
	if nonce != "" {
		idClaims["nonce"] = nonce
	}
	accessClaims := map[string]any{
		"iss":    *issuerFlag,
		"aud":    "lexicon-api",
		"sub":    "user-e2e",
		"email":  "admin@example.test",
		"iat":    now.Unix(),
		"exp":    now.Add(30 * time.Second).Unix(),
		"groups": []string{"super_admin"},
	}

	idJWT, err := signRS256(idClaims)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	accessJWT, err := signRS256(accessClaims)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	resp := map[string]any{
		"access_token":  accessJWT,
		"refresh_token": "refresh-" + randString(16),
		"token_type":    "Bearer",
		"expires_in":    30,
		"id_token":      idJWT,
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(resp)
}

func logout(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	w.Header().Set("Content-Type", "text/plain")
	_, _ = fmt.Fprintf(w, "fake-authentik end_session ok id_token_hint=%s post_logout=%s\n",
		q.Get("id_token_hint"), q.Get("post_logout_redirect_uri"))
}

func respondOAuthErr(w http.ResponseWriter, code, desc string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusBadRequest)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"error":             code,
		"error_description": desc,
	})
}

func signRS256(claims map[string]any) (string, error) {
	header := map[string]any{
		"alg": "RS256",
		"typ": "JWT",
		"kid": key.kid,
	}
	hJSON, err := json.Marshal(header)
	if err != nil {
		return "", err
	}
	cJSON, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}
	h := base64.RawURLEncoding.EncodeToString(hJSON)
	c := base64.RawURLEncoding.EncodeToString(cJSON)
	signingInput := h + "." + c
	hash := sha256.Sum256([]byte(signingInput))
	sig, err := rsa.SignPKCS1v15(rand.Reader, key.priv, crypto.SHA256, hash[:])
	if err != nil {
		return "", err
	}
	return signingInput + "." + base64.RawURLEncoding.EncodeToString(sig), nil
}

func randString(n int) string {
	b := make([]byte, n)
	_, _ = rand.Read(b)
	return base64.RawURLEncoding.EncodeToString(b)[:n]
}
