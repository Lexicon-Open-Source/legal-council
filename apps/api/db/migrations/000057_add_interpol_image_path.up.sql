-- Add image_path column to store Garage object storage path for notice photos
ALTER TABLE crawler.interpol_red_notices
    ADD COLUMN image_path TEXT;

COMMENT ON COLUMN crawler.interpol_red_notices.image_path IS 'Garage object storage path for notice photo (e.g., interpol/2025-96936.jpg)';
