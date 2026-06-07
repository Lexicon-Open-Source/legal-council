-- Remove image_path column
ALTER TABLE crawler.interpol_red_notices
    DROP COLUMN IF EXISTS image_path;
