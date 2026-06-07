package api

import (
	"bytes"
	"context"
	"errors"
	"io"
	"mime"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/lexiconindonesia/lexicon-backend/internal/i18n"
)

// Council-specific constants
const (
	councilTimeout        = 120 * time.Second // For AI processing
	councilOpinionTimeout = 300 * time.Second // For opinion generation (synthesis + structured summary, 5 min)
	councilStreamTimeout  = 300 * time.Second // For streaming (5 min)
)

// =============================================================================
// Session Endpoints
// =============================================================================

// CreateCouncilSession handles POST /v1/council/sessions
func (s *Server) CreateCouncilSession(w http.ResponseWriter, r *http.Request) {
	if acceptsEventStream(r.Header.Get("Accept")) {
		s.proxyCouncilSSE(w, r, http.MethodPost, "/council/sessions")
		return
	}

	s.proxyCouncilRequest(w, r, http.MethodPost, "/council/sessions", councilTimeout)
}

// ListCouncilSessions handles GET /v1/council/sessions
func (s *Server) ListCouncilSessions(w http.ResponseWriter, r *http.Request, params ListCouncilSessionsParams) {
	// Preserve query params
	path := "/council/sessions"
	if r.URL.RawQuery != "" {
		path += "?" + r.URL.RawQuery
	}
	s.proxyCouncilRequest(w, r, http.MethodGet, path, councilTimeout)
}

// GetCouncilSession handles GET /v1/council/sessions/{session_id}
func (s *Server) GetCouncilSession(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilRequest(w, r, http.MethodGet, "/council/sessions/"+sessionID, councilTimeout)
}

// DeleteCouncilSession handles DELETE /v1/council/sessions/{session_id}
func (s *Server) DeleteCouncilSession(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilRequest(w, r, http.MethodDelete, "/council/sessions/"+sessionID, councilTimeout)
}

// ConcludeCouncilSession handles POST /v1/council/sessions/{session_id}/conclude
func (s *Server) ConcludeCouncilSession(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilRequest(w, r, http.MethodPost, "/council/sessions/"+sessionID+"/conclude", councilTimeout)
}

// =============================================================================
// Deliberation Endpoints (Non-Streaming)
// =============================================================================

// SendCouncilMessage handles POST /v1/council/deliberation/{session_id}/message
func (s *Server) SendCouncilMessage(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilRequest(w, r, http.MethodPost, "/council/deliberation/"+sessionID+"/message", councilTimeout)
}

// ContinueCouncilDiscussion handles POST /v1/council/deliberation/{session_id}/continue
func (s *Server) ContinueCouncilDiscussion(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilRequest(w, r, http.MethodPost, "/council/deliberation/"+sessionID+"/continue", councilTimeout)
}

// GetCouncilMessages handles GET /v1/council/deliberation/{session_id}/messages
func (s *Server) GetCouncilMessages(w http.ResponseWriter, r *http.Request, sessionID string, params GetCouncilMessagesParams) {
	path := "/council/deliberation/" + sessionID + "/messages"
	if r.URL.RawQuery != "" {
		path += "?" + r.URL.RawQuery
	}
	s.proxyCouncilRequest(w, r, http.MethodGet, path, councilTimeout)
}

// =============================================================================
// Opinion Endpoints
// =============================================================================

// GenerateCouncilOpinion handles POST /v1/council/deliberation/{session_id}/opinion
func (s *Server) GenerateCouncilOpinion(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilRequest(w, r, http.MethodPost, "/council/deliberation/"+sessionID+"/opinion", councilOpinionTimeout)
}

// GetCouncilOpinion handles GET /v1/council/deliberation/{session_id}/opinion
func (s *Server) GetCouncilOpinion(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilRequest(w, r, http.MethodGet, "/council/deliberation/"+sessionID+"/opinion", councilTimeout)
}

// =============================================================================
// Streaming Endpoints (SSE)
// =============================================================================

// StreamCouncilInitial handles POST /v1/council/deliberation/{session_id}/stream/initial
func (s *Server) StreamCouncilInitial(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilSSE(w, r, http.MethodPost, "/council/deliberation/"+sessionID+"/stream/initial")
}

// StreamCouncilMessage handles POST /v1/council/deliberation/{session_id}/stream/message
func (s *Server) StreamCouncilMessage(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilSSE(w, r, http.MethodPost, "/council/deliberation/"+sessionID+"/stream/message")
}

// StreamCouncilContinue handles POST /v1/council/deliberation/{session_id}/stream/continue
func (s *Server) StreamCouncilContinue(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilSSE(w, r, http.MethodPost, "/council/deliberation/"+sessionID+"/stream/continue")
}

// =============================================================================
// PDF Download
// =============================================================================

// DownloadCouncilPDF handles GET /v1/council/deliberation/{session_id}/download/pdf
func (s *Server) DownloadCouncilPDF(w http.ResponseWriter, r *http.Request, sessionID string) {
	s.proxyCouncilRequest(w, r, http.MethodGet, "/council/deliberation/"+sessionID+"/download/pdf", councilTimeout)
}

// =============================================================================
// Case Search Endpoints
// =============================================================================

// SearchCouncilCases handles POST /v1/council/cases/search
func (s *Server) SearchCouncilCases(w http.ResponseWriter, r *http.Request) {
	s.proxyCouncilRequest(w, r, http.MethodPost, "/council/cases/search", councilTimeout)
}

// SearchCouncilCasesGet handles GET /v1/council/cases/search
func (s *Server) SearchCouncilCasesGet(w http.ResponseWriter, r *http.Request, params SearchCouncilCasesGetParams) {
	query := strings.TrimSpace(params.Query)
	if query == "" {
		writeError(w, i18n.T(r.Context(), i18n.MsgErrorScreeningInvalidQuery), http.StatusBadRequest)
		return
	}
	if len(query) > 500 {
		writeError(w, i18n.T(r.Context(), i18n.MsgErrorQueryTooLong), http.StatusBadRequest)
		return
	}
	if params.CaseType != nil && !params.CaseType.Valid() {
		writeError(w, i18n.T(r.Context(), i18n.MsgErrorCouncilInvalidCaseType), http.StatusBadRequest)
		return
	}

	path := "/council/cases/search"
	if r.URL.RawQuery != "" {
		path += "?" + r.URL.RawQuery
	}
	s.proxyCouncilRequest(w, r, http.MethodGet, path, councilTimeout)
}

// GetCouncilCasesByType handles GET /v1/council/cases/by-type/{case_type}
func (s *Server) GetCouncilCasesByType(w http.ResponseWriter, r *http.Request, caseType CouncilCaseType, params GetCouncilCasesByTypeParams) {
	if !caseType.Valid() {
		writeError(w, i18n.T(r.Context(), i18n.MsgErrorCouncilInvalidCaseType), http.StatusBadRequest)
		return
	}

	path := "/council/cases/by-type/" + string(caseType)
	if r.URL.RawQuery != "" {
		path += "?" + r.URL.RawQuery
	}
	s.proxyCouncilRequest(w, r, http.MethodGet, path, councilTimeout)
}

// GetCouncilCase handles GET /v1/council/cases/{case_id}
func (s *Server) GetCouncilCase(w http.ResponseWriter, r *http.Request, caseID string) {
	s.proxyCouncilRequest(w, r, http.MethodGet, "/council/cases/"+caseID, councilTimeout)
}

// GetCouncilCaseStatistics handles GET /v1/council/cases/statistics
func (s *Server) GetCouncilCaseStatistics(w http.ResponseWriter, r *http.Request) {
	s.proxyCouncilRequest(w, r, http.MethodGet, "/council/cases/statistics", councilTimeout)
}

// =============================================================================
// Helper Methods
// =============================================================================

func acceptsEventStream(acceptHeader string) bool {
	for _, part := range strings.Split(acceptHeader, ",") {
		mediaType, params, err := mime.ParseMediaType(strings.TrimSpace(part))
		if err != nil {
			continue
		}
		if strings.ToLower(mediaType) != "text/event-stream" {
			continue
		}
		q := strings.TrimSpace(params["q"])
		if q == "" {
			return true
		}
		quality, err := strconv.ParseFloat(q, 64)
		if err != nil {
			continue
		}
		if quality > 0 {
			return true
		}
	}
	return false
}

// proxyCouncilRequest forwards a request to the council service
func (s *Server) proxyCouncilRequest(w http.ResponseWriter, r *http.Request, method, path string, timeout time.Duration) {
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	start := time.Now()
	success := false
	defer func() {
		if s.metrics != nil {
			s.metrics.RecordLLMRequest(ctx, time.Since(start), success)
		}
	}()

	// Build request URL (council endpoints are now served by LLM service)
	requestURL := s.cfg.LLMServiceURL + path

	// Read body if present
	var bodyReader io.Reader
	if r.Body != nil && r.ContentLength != 0 {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			writeError(w, i18n.T(ctx, i18n.MsgErrorCouncilReadBodyFailed), http.StatusBadRequest)
			return
		}
		bodyReader = bytes.NewReader(body)
	}

	// Create request
	httpReq, err := http.NewRequestWithContext(ctx, method, requestURL, bodyReader)
	if err != nil {
		writeError(w, i18n.T(ctx, i18n.MsgErrorCouncilCreateRequestFailed), http.StatusInternalServerError)
		return
	}

	// Set headers
	httpReq.Header.Set("X-API-KEY", s.cfg.LLMAPIKey)
	if r.Header.Get("Content-Type") != "" {
		httpReq.Header.Set("Content-Type", r.Header.Get("Content-Type"))
	} else {
		httpReq.Header.Set("Content-Type", "application/json")
	}

	// Propagate user context (when auth is added)
	if userID := r.Header.Get("X-User-ID"); userID != "" {
		httpReq.Header.Set("X-User-ID", userID)
	}

	// Execute request
	resp, err := s.llmHTTP.Do(httpReq)
	if err != nil {
		s.handleCouncilError(w, r, err)
		return
	}
	defer func() { _ = resp.Body.Close() }()

	// Mark as success if we got a valid response (even non-2xx is a valid LLM response)
	success = true

	// Copy response headers
	for key, values := range resp.Header {
		for _, value := range values {
			w.Header().Add(key, value)
		}
	}

	// Forward status and body
	w.WriteHeader(resp.StatusCode)
	_, _ = io.Copy(w, resp.Body)
}

// proxyCouncilSSE forwards an SSE stream from the council service
func (s *Server) proxyCouncilSSE(w http.ResponseWriter, r *http.Request, method, path string) {
	ctx, cancel := context.WithTimeout(r.Context(), councilStreamTimeout)
	defer cancel()

	start := time.Now()
	success := false
	defer func() {
		if s.metrics != nil {
			s.metrics.RecordLLMRequest(ctx, time.Since(start), success)
		}
	}()

	// Build request URL (council endpoints are now served by LLM service)
	requestURL := s.cfg.LLMServiceURL + path

	// Read body if present
	var bodyReader io.Reader
	if r.Body != nil && r.ContentLength != 0 {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			writeError(w, i18n.T(ctx, i18n.MsgErrorCouncilReadBodyFailed), http.StatusBadRequest)
			return
		}
		bodyReader = bytes.NewReader(body)
	}

	// Create request
	httpReq, err := http.NewRequestWithContext(ctx, method, requestURL, bodyReader)
	if err != nil {
		writeError(w, i18n.T(ctx, i18n.MsgErrorCouncilCreateRequestFailed), http.StatusInternalServerError)
		return
	}

	// Set headers
	httpReq.Header.Set("X-API-KEY", s.cfg.LLMAPIKey)
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Accept", "text/event-stream")

	// Execute request
	resp, err := s.llmHTTP.Do(httpReq)
	if err != nil {
		s.handleCouncilError(w, r, err)
		return
	}
	defer func() { _ = resp.Body.Close() }()

	// Mark as success if we got a response
	success = true

	// Check for error response
	if resp.StatusCode != http.StatusOK {
		w.WriteHeader(resp.StatusCode)
		_, _ = io.Copy(w, resp.Body)
		return
	}

	// Set SSE headers
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("X-Accel-Buffering", "no")

	flusher, ok := w.(http.Flusher)
	if !ok {
		writeError(w, i18n.T(ctx, i18n.MsgErrorCouncilStreamingUnsupported), http.StatusInternalServerError)
		return
	}

	// Stream response
	buf := make([]byte, 1024)
	for {
		n, err := resp.Body.Read(buf)
		if n > 0 {
			_, _ = w.Write(buf[:n])
			flusher.Flush()
		}
		if err != nil {
			if err != io.EOF {
				s.logger.Error("SSE stream error", "error", err)
			}
			break
		}
	}
}

// handleCouncilError handles errors from the council service
func (s *Server) handleCouncilError(w http.ResponseWriter, r *http.Request, err error) {
	requestID, _ := r.Context().Value(requestIDKey).(string)

	// Log the full error internally
	s.logger.Error("Council service error",
		"error", err.Error(),
		"request_id", requestID,
	)

	// Determine user-friendly message based on error type
	ctx := r.Context()
	var userMessage string
	if errors.Is(err, context.DeadlineExceeded) {
		userMessage = i18n.T(ctx, i18n.MsgErrorCouncilTimeout)
	} else if errors.Is(err, context.Canceled) {
		userMessage = i18n.T(ctx, i18n.MsgErrorCouncilCancelled)
	} else {
		userMessage = i18n.T(ctx, i18n.MsgErrorCouncilServiceUnavailable)
	}

	writeError(w, userMessage, http.StatusServiceUnavailable)
}
