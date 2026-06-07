package api

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"
)

// turnstileSessionConfig holds settings for session token generation and verification.
type turnstileSessionConfig struct {
	// SecretKey is the HMAC-SHA256 signing key (raw bytes, minimum 32 bytes).
	SecretKey []byte
	// TTL is the session token validity duration.
	TTL time.Duration
	// GracePeriod is the clock-skew tolerance added to TTL when verifying expiry.
	GracePeriod time.Duration
}

// Session token errors.
var (
	errSessionTokenMalformed = errors.New("malformed session token")
	errSessionTokenExpired   = errors.New("session token expired")
	errSessionTokenInvalid   = errors.New("invalid session token signature")
)

// sessionTokenNonceBytes is the number of random bytes in the nonce (16 bytes = 32 hex chars).
const sessionTokenNonceBytes = 16

// generateSessionToken creates a signed, time-limited session token.
//
// Token format: base64url(payload).base64url(signature)
// Payload format: "expiry_unix|nonce_hex"
//
// The nonce provides uniqueness — each token is distinct even when issued in
// the same second. The expiry is checked during verification.
func generateSessionToken(cfg turnstileSessionConfig) (string, error) {
	// Generate random nonce
	nonce := make([]byte, sessionTokenNonceBytes)
	if _, err := rand.Read(nonce); err != nil {
		return "", fmt.Errorf("generate nonce: %w", err)
	}

	expiry := time.Now().Add(cfg.TTL).Unix()
	payload := fmt.Sprintf("%d|%s", expiry, hex.EncodeToString(nonce))

	// Sign the payload
	sig := computeHMAC([]byte(payload), cfg.SecretKey)

	// Encode as base64url (no padding) separated by dot
	token := base64.RawURLEncoding.EncodeToString([]byte(payload)) +
		"." +
		base64.RawURLEncoding.EncodeToString(sig)

	return token, nil
}

// verifySessionToken validates the HMAC signature and checks the expiry.
// Returns nil on success.
func verifySessionToken(cfg turnstileSessionConfig, token string) error {
	parts := strings.SplitN(token, ".", 2)
	if len(parts) != 2 {
		return errSessionTokenMalformed
	}

	payloadBytes, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		return errSessionTokenMalformed
	}

	sigBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return errSessionTokenMalformed
	}

	// Verify HMAC signature (constant-time comparison)
	expectedSig := computeHMAC(payloadBytes, cfg.SecretKey)
	if !hmac.Equal(sigBytes, expectedSig) {
		return errSessionTokenInvalid
	}

	// Parse payload: "expiry_unix|nonce_hex"
	payload := string(payloadBytes)
	pipeIdx := strings.IndexByte(payload, '|')
	if pipeIdx < 0 {
		return errSessionTokenMalformed
	}

	expiryStr := payload[:pipeIdx]
	expiryUnix, err := strconv.ParseInt(expiryStr, 10, 64)
	if err != nil {
		return errSessionTokenMalformed
	}

	// Check expiry with grace period for clock skew
	deadline := time.Unix(expiryUnix, 0).Add(cfg.GracePeriod)
	if time.Now().After(deadline) {
		return errSessionTokenExpired
	}

	return nil
}

// computeHMAC produces an HMAC-SHA256 digest.
func computeHMAC(data, key []byte) []byte {
	mac := hmac.New(sha256.New, key)
	mac.Write(data)
	return mac.Sum(nil)
}

// decodeHexKey decodes a hex-encoded string into raw bytes.
// Panics on invalid hex (should be validated at config load time).
func decodeHexKey(hexStr string) []byte {
	key, err := hex.DecodeString(hexStr)
	if err != nil {
		panic(fmt.Sprintf("invalid hex key: %v", err))
	}
	return key
}
