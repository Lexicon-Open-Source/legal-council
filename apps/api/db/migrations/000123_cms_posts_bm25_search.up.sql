-- Add ParadeDB BM25 search for published CMS posts.
-- pg_search BM25 index DDL does not support CONCURRENTLY in this project stack;
-- cms.posts is MVP-scale (<1k rows expected), so the brief CREATE INDEX lock is acceptable.
CREATE INDEX idx_cms_posts_bm25 ON cms.posts
USING bm25 (id, title, title_en, content_plain, content_plain_en, excerpt, tags)
WITH (key_field='id');
