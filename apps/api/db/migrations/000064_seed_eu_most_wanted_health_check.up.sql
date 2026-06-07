-- Seed eu_most_wanted into health_checks (was added after the original seed in 000061)
INSERT INTO crawler.health_checks (crawler_type)
VALUES ('eu_most_wanted')
ON CONFLICT (crawler_type) DO NOTHING;
