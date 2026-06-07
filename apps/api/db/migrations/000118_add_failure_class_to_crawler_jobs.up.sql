CREATE TYPE crawler.failure_class AS ENUM (
    'site_down',
    'layout_changed',
    'rate_limited',
    'timeout',
    'browser_crashed',
    'data_quality',
    'unknown'
);

ALTER TABLE crawler.crawler_jobs
ADD COLUMN failure_class crawler.failure_class;
