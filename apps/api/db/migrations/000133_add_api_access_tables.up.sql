-- API access management: clients, hashed+scoped keys, per-client quotas, usage logs.
-- Supports commercial API products (e.g. AML screening) with revocable credentials,
-- per-client rate limits/quotas, and billable usage tracking.

CREATE TABLE app.api_clients (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        text NOT NULL,
    description text NOT NULL DEFAULT '',
    status      text NOT NULL DEFAULT 'active',
    created_at  timestamp with time zone NOT NULL DEFAULT now(),
    updated_at  timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT api_clients_status_check
        CHECK (status IN ('active', 'suspended', 'disabled'))
);

CREATE TABLE app.api_keys (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id    uuid NOT NULL REFERENCES app.api_clients(id) ON DELETE CASCADE,
    key_prefix   text NOT NULL,
    key_hash     text NOT NULL,
    key_scope    text[] NOT NULL DEFAULT '{}',
    status       text NOT NULL DEFAULT 'active',
    last_used_at timestamp with time zone,
    expires_at   timestamp with time zone,
    created_at   timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT api_keys_status_check
        CHECK (status IN ('active', 'revoked', 'expired'))
);

CREATE INDEX idx_api_keys_prefix ON app.api_keys (key_prefix);
CREATE INDEX idx_api_keys_client ON app.api_keys (client_id);

CREATE TABLE app.api_quotas (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id    uuid NOT NULL REFERENCES app.api_clients(id) ON DELETE CASCADE,
    scope        text NOT NULL,
    quota_limit  bigint NOT NULL,
    window_start timestamp with time zone NOT NULL,
    window_end   timestamp with time zone NOT NULL,
    used         bigint NOT NULL DEFAULT 0,
    created_at   timestamp with time zone NOT NULL DEFAULT now(),
    updated_at   timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT api_quotas_client_scope_window_unique
        UNIQUE (client_id, scope, window_start)
);

CREATE INDEX idx_api_quotas_client_scope ON app.api_quotas (client_id, scope);

-- Partitioned by range on logged_at to bound table growth. A primary key on a
-- partitioned table must include the partition column, so this table has no
-- single-column PK; reporting reads use the (client_id, logged_at) index.
CREATE TABLE app.api_usage_logs (
    id          bigserial NOT NULL,
    client_id   uuid NOT NULL REFERENCES app.api_clients(id),
    key_id      uuid NOT NULL REFERENCES app.api_keys(id),
    endpoint    text NOT NULL,
    method      text NOT NULL,
    status_code integer NOT NULL,
    latency_ms  integer NOT NULL,
    billable    boolean NOT NULL DEFAULT true,
    request_id  text,
    logged_at   timestamp with time zone NOT NULL DEFAULT now()
) PARTITION BY RANGE (logged_at);

CREATE INDEX idx_api_usage_logs_client_logged
    ON app.api_usage_logs (client_id, logged_at DESC);

CREATE INDEX idx_api_usage_logs_logged_at
    ON app.api_usage_logs (logged_at DESC);

-- Initial monthly partition. Follow-up work adds automated partition management.
CREATE TABLE app.api_usage_logs_202606 PARTITION OF app.api_usage_logs
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
