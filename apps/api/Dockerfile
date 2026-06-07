# Build stage - Debian Bookworm with glibc
FROM golang:1.26-bookworm AS builder
WORKDIR /app

# Download dependencies first (better layer caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy source. Generated code (internal/api/api.gen.go) is committed, so no
# codegen step is needed at build time.
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server ./cmd/api

# Runtime stage - Debian Bookworm slim
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/server /app/server
EXPOSE 8000
ENTRYPOINT ["/app/server"]
