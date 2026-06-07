DROP INDEX IF EXISTS idx_cms_files_upload_status;

ALTER TABLE cms.files
    DROP CONSTRAINT IF EXISTS files_upload_status_check;

ALTER TABLE cms.files
    DROP COLUMN IF EXISTS upload_status,
    DROP COLUMN IF EXISTS public_url,
    DROP COLUMN IF EXISTS alt_text,
    DROP COLUMN IF EXISTS title;
