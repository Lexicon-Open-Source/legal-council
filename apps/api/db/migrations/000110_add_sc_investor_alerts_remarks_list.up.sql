-- Add remarks_list JSONB column to sc_investor_alerts for structured bullet points.
-- The existing remarks TEXT column is preserved for backwards compatibility.
ALTER TABLE crawler.sc_investor_alerts
    ADD COLUMN IF NOT EXISTS remarks_list JSONB NOT NULL DEFAULT '[]';

-- Change date_added from DATE to TEXT to preserve raw source values.
-- The SC Malaysia source often provides year-only ("2026") rather than full dates.
-- Storing as TEXT avoids fabricating month/day values.
ALTER TABLE crawler.sc_investor_alerts
    ALTER COLUMN date_added TYPE TEXT USING date_added::TEXT;
