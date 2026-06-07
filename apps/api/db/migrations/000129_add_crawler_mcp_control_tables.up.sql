CREATE TABLE crawler.mcp_action_previews (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    token_hash text NOT NULL UNIQUE,
    client_id text NOT NULL,
    operator_ref text,
    original_text text NOT NULL,
    action_kind text NOT NULL,
    actions jsonb NOT NULL,
    summary jsonb DEFAULT '{}'::jsonb NOT NULL,
    parser_provider text,
    parser_model text,
    confidence numeric,
    validation_result jsonb DEFAULT '{}'::jsonb NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    consumed_at timestamp with time zone,
    consumed_by text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mcp_action_previews_action_kind_check
        CHECK (action_kind IN ('crawl', 'schedule')),
    CONSTRAINT mcp_action_previews_actions_array_check
        CHECK (jsonb_typeof(actions) = 'array'),
    CONSTRAINT mcp_action_previews_summary_object_check
        CHECK (jsonb_typeof(summary) = 'object'),
    CONSTRAINT mcp_action_previews_validation_result_object_check
        CHECK (jsonb_typeof(validation_result) = 'object'),
    CONSTRAINT mcp_action_previews_confidence_range_check
        CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1)),
    CONSTRAINT mcp_action_previews_consumed_by_requires_consumed_at_check
        CHECK (consumed_by IS NULL OR consumed_at IS NOT NULL)
);

CREATE INDEX idx_mcp_action_previews_client_created
    ON crawler.mcp_action_previews (client_id, created_at DESC);

CREATE INDEX idx_mcp_action_previews_expires_at
    ON crawler.mcp_action_previews (expires_at)
    WHERE consumed_at IS NULL;

CREATE TABLE crawler.mcp_audit_events (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    preview_id uuid,
    event_type text NOT NULL,
    client_id text NOT NULL,
    operator_ref text,
    original_text text,
    parser_provider text,
    parser_model text,
    llm_output jsonb DEFAULT '{}'::jsonb NOT NULL,
    deterministic_result jsonb DEFAULT '{}'::jsonb NOT NULL,
    submitted_results jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mcp_audit_events_event_type_check
        CHECK (
            event_type IN (
                'parse',
                'preview',
                'auto_submit',
                'confirm',
                'reject',
                'ambiguous',
                'failed'
            )
        ),
    CONSTRAINT mcp_audit_events_llm_output_object_check
        CHECK (jsonb_typeof(llm_output) = 'object'),
    CONSTRAINT mcp_audit_events_deterministic_result_object_check
        CHECK (jsonb_typeof(deterministic_result) = 'object'),
    CONSTRAINT mcp_audit_events_submitted_results_array_check
        CHECK (jsonb_typeof(submitted_results) = 'array')
);

CREATE INDEX idx_mcp_audit_events_preview_created
    ON crawler.mcp_audit_events (preview_id, created_at DESC);

CREATE INDEX idx_mcp_audit_events_client_created
    ON crawler.mcp_audit_events (client_id, created_at DESC);

CREATE INDEX idx_mcp_audit_events_event_created
    ON crawler.mcp_audit_events (event_type, created_at DESC);
