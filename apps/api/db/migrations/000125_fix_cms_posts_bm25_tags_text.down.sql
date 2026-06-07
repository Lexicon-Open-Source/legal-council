DROP INDEX IF EXISTS cms.idx_cms_posts_bm25;

CREATE INDEX idx_cms_posts_bm25 ON cms.posts
USING bm25 (id, title, title_en, content_plain, content_plain_en, excerpt, tags)
WITH (key_field='id');

ALTER TABLE cms.posts DROP COLUMN IF EXISTS tags_text;

DROP FUNCTION IF EXISTS cms.array_to_text_immutable(TEXT[]);
