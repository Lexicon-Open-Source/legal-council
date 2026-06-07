ALTER TABLE cms.files
    ADD COLUMN title TEXT NOT NULL DEFAULT '',
    ADD COLUMN alt_text TEXT NOT NULL DEFAULT '',
    ADD COLUMN public_url TEXT NOT NULL DEFAULT '',
    ADD COLUMN upload_status TEXT NOT NULL DEFAULT 'confirmed';

ALTER TABLE cms.files
    ADD CONSTRAINT files_upload_status_check
        CHECK (upload_status IN ('pending', 'confirmed'));

CREATE INDEX idx_cms_files_upload_status
    ON cms.files (upload_status)
    WHERE deleted_at IS NULL;
