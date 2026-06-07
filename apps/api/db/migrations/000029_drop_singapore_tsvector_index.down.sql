-- Recreate tsvector index (WARNING: will fail if content > 1MB exists)
CREATE INDEX idx_sg_judgments_content_search
ON crawler.singapore_judgments
USING gin(to_tsvector('english', COALESCE(content, '')));
