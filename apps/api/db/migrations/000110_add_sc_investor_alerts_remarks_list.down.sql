ALTER TABLE crawler.sc_investor_alerts
    ALTER COLUMN date_added TYPE DATE USING date_added::DATE;

ALTER TABLE crawler.sc_investor_alerts
    DROP COLUMN IF EXISTS remarks_list;
