package api

import (
	"context"
	"encoding/json"
	"net/http"
	"time"
)

type healthResponse struct {
	Status string `json:"status"`
}

type readyResponse struct {
	Status   string `json:"status"`
	Database string `json:"database"`
	Redis    string `json:"redis"`
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(healthResponse{Status: "ok"})
}

func (s *Server) handleReady(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	response := readyResponse{
		Status:   "ready",
		Database: "unknown",
		Redis:    "unknown",
	}

	// Check database
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	if err := s.db.Ping(ctx); err != nil {
		response.Status = "not ready"
		response.Database = "unhealthy"
	} else {
		response.Database = "healthy"
	}

	// Check Redis
	ctx, cancel = context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	if err := s.redis.Ping(ctx).Err(); err != nil {
		response.Status = "not ready"
		response.Redis = "unhealthy"
	} else {
		response.Redis = "healthy"
	}

	// Set appropriate status code
	statusCode := http.StatusOK
	if response.Status == "not ready" {
		statusCode = http.StatusServiceUnavailable
	}

	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(response)
}

// GetHealth is the ServerInterface method (delegates to handleHealth)
func (s *Server) GetHealth(w http.ResponseWriter, r *http.Request) {
	s.handleHealth(w, r)
}

// GetReady is the ServerInterface method (delegates to handleReady)
func (s *Server) GetReady(w http.ResponseWriter, r *http.Request) {
	s.handleReady(w, r)
}
