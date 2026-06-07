-- Add content column to store full judgment text
ALTER TABLE crawler.singapore_judgments
ADD COLUMN content TEXT;

-- Add index for full-text search (optional, can be useful for searching)
CREATE INDEX idx_sg_judgments_content_search
ON crawler.singapore_judgments
USING gin(to_tsvector('english', COALESCE(content, '')));
