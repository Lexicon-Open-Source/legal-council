package api

import (
	"fmt"
	"net/http"
	"time"

	"github.com/lexiconindonesia/lexicon-backend/internal/config"
	"github.com/lexiconindonesia/lexicon-backend/internal/httpclient"
)

func newLLMHTTPClient(cfg *config.Config) (*http.Client, error) {
	class, err := config.ClassifyLLMServiceURL(cfg.LLMServiceURL, cfg.Environment)
	if err != nil {
		return nil, err
	}

	switch class {
	case config.LLMServiceURLInternalService:
		return httpclient.NewInternalServiceClient(120*time.Second, config.GetAllowedInternalLLMServiceHosts(cfg.Environment))
	case config.LLMServiceURLDevelopmentLocal:
		return httpclient.NewDevelopmentLocalClient(120*time.Second, config.GetAllowedDevelopmentLocalLLMServiceHosts()), nil
	case config.LLMServiceURLPublicOutbound:
		return httpclient.NewPublicOutboundClient(120*time.Second, config.GetAllowedPublicLLMServiceHosts(cfg.Environment)), nil
	default:
		return nil, fmt.Errorf("unsupported LLM service URL class: %s", class)
	}
}
