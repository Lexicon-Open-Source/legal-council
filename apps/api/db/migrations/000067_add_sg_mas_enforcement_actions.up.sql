CREATE TABLE IF NOT EXISTS crawler.sg_mas_enforcement_actions (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Natural key (detail page URL path)
    source_url TEXT NOT NULL UNIQUE,

    -- From list table
    title TEXT NOT NULL,
    issue_date DATE,
    action_type TEXT,

    -- From detail page
    headline TEXT,
    content TEXT,

    -- Raw scraped data for reprocessing
    raw_data JSONB NOT NULL DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-update trigger
CREATE TRIGGER update_sg_mas_enforcement_actions_updated_at
    BEFORE UPDATE ON crawler.sg_mas_enforcement_actions
    FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();

-- Indexes
CREATE INDEX idx_sg_mas_action_type ON crawler.sg_mas_enforcement_actions (action_type)
    WHERE action_type IS NOT NULL;
CREATE INDEX idx_sg_mas_issue_date ON crawler.sg_mas_enforcement_actions (issue_date DESC)
    WHERE issue_date IS NOT NULL;

-- Trigram index for title search
CREATE INDEX idx_sg_mas_title_trgm ON crawler.sg_mas_enforcement_actions
    USING GIN (title gin_trgm_ops);

COMMENT ON TABLE crawler.sg_mas_enforcement_actions
    IS 'MAS Singapore formal enforcement actions (prohibition orders, civil penalties, etc.)';
COMMENT ON COLUMN crawler.sg_mas_enforcement_actions.source_url
    IS 'Detail page URL (natural key for deduplication)';
COMMENT ON COLUMN crawler.sg_mas_enforcement_actions.action_type
    IS 'Free text from MAS: Prohibition Order, Civil Penalty, Composition Penalty, Reprimand, etc.';
COMMENT ON COLUMN crawler.sg_mas_enforcement_actions.content
    IS 'Full article body as markdown (converted from HTML via html2text)';
