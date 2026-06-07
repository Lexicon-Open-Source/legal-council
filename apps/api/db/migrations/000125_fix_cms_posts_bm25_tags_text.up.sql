-- array_to_string is STABLE in PostgreSQL, but generated columns require
-- IMMUTABLE expressions. This wrapper is safe because array_to_string with
-- a fixed separator is fully deterministic for any given input.
CREATE OR REPLACE FUNCTION cms.array_to_text_immutable(arr TEXT[])
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
SELECT array_to_string(arr, ' ')
$$;

-- Add generated column that flattens the tags array to a plain TEXT string
-- so it can be included in the BM25 index without TEXT[] issues in pg_search.
ALTER TABLE cms.posts
    ADD COLUMN tags_text TEXT
    GENERATED ALWAYS AS (cms.array_to_text_immutable(tags)) STORED;

-- Recreate the BM25 index using tags_text instead of the TEXT[] tags column.
-- Index lives in the cms schema (same as the table); schema-qualify the DROP.
DROP INDEX IF EXISTS cms.idx_cms_posts_bm25;

CREATE INDEX idx_cms_posts_bm25 ON cms.posts
USING bm25 (id, title, title_en, content_plain, content_plain_en, excerpt, tags_text)
WITH (key_field='id');
