# syntax=docker/dockerfile:1

FROM python:3.14-slim AS base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv for faster dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml ./

# Install dependencies
RUN uv pip install --system -r pyproject.toml

# Copy application code
COPY main.py settings.py ./
COPY src ./src

# Bootstrap OpenTelemetry (auto-detects libraries like fastapi, sqlalchemy and installs their instrumentations)
# This runs AFTER copying app code so it can detect what libraries are used
RUN opentelemetry-bootstrap -a install

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Run with OpenTelemetry auto-instrumentation
# Required env vars: OTEL_SERVICE_NAME, OTEL_EXPORTER_OTLP_ENDPOINT
# To disable: set OTEL_TRACES_EXPORTER=none, OTEL_METRICS_EXPORTER=none, OTEL_LOGS_EXPORTER=none
# IMPORTANT: Don't use --reload in production (breaks OTel instrumentation)
CMD ["opentelemetry-instrument", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
