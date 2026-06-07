-- Create CMS schema for content management
CREATE SCHEMA IF NOT EXISTS cms;
COMMENT ON SCHEMA cms IS 'Content management system tables for admin-managed website content.';

-- Static pages (company profile, vision/mission, about, contact, custom)
CREATE TABLE cms.pages (
    id              TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    title_en        TEXT NOT NULL DEFAULT '',
    slug            TEXT NOT NULL,
    content         JSONB NOT NULL DEFAULT '{}',
    content_en      JSONB NOT NULL DEFAULT '{}',
    content_plain   TEXT NOT NULL DEFAULT '',
    content_plain_en TEXT NOT NULL DEFAULT '',
    page_type       TEXT NOT NULL DEFAULT 'custom' CHECK (page_type IN ('profile', 'vision_mission', 'about', 'contact', 'custom')),
    sort_order      INT NOT NULL DEFAULT 0,
    status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
    published_at    TIMESTAMPTZ,
    created_by      TEXT NOT NULL DEFAULT '',
    updated_by      TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);
COMMENT ON TABLE cms.pages IS 'Static pages for the website (company profile, vision/mission, etc.)';

CREATE UNIQUE INDEX idx_cms_pages_slug ON cms.pages (slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_cms_pages_sort_order ON cms.pages (sort_order);
CREATE INDEX idx_cms_pages_status ON cms.pages (status) WHERE deleted_at IS NULL;
CREATE INDEX idx_cms_pages_fts ON cms.pages USING gin(to_tsvector('simple', content_plain));
CREATE INDEX idx_cms_pages_fts_en ON cms.pages USING gin(to_tsvector('simple', content_plain_en));

-- Blog posts / news
CREATE TABLE cms.posts (
    id              TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    title_en        TEXT NOT NULL DEFAULT '',
    slug            TEXT NOT NULL,
    content         JSONB NOT NULL DEFAULT '{}',
    content_en      JSONB NOT NULL DEFAULT '{}',
    content_plain   TEXT NOT NULL DEFAULT '',
    content_plain_en TEXT NOT NULL DEFAULT '',
    excerpt         TEXT NOT NULL DEFAULT '',
    cover_image_url TEXT NOT NULL DEFAULT '',
    tags            TEXT[] NOT NULL DEFAULT '{}',
    status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
    published_at    TIMESTAMPTZ,
    created_by      TEXT NOT NULL DEFAULT '',
    updated_by      TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);
COMMENT ON TABLE cms.posts IS 'Blog posts and news articles';

CREATE UNIQUE INDEX idx_cms_posts_slug ON cms.posts (slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_cms_posts_published_at ON cms.posts (published_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_cms_posts_tags ON cms.posts USING gin(tags);
CREATE INDEX idx_cms_posts_status ON cms.posts (status) WHERE deleted_at IS NULL;
CREATE INDEX idx_cms_posts_fts ON cms.posts USING gin(to_tsvector('simple', content_plain));
CREATE INDEX idx_cms_posts_fts_en ON cms.posts USING gin(to_tsvector('simple', content_plain_en));

-- File manager (documents, images, training materials)
CREATE TABLE cms.files (
    id              TEXT PRIMARY KEY,
    filename        TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    mime_type       TEXT NOT NULL,
    file_size       BIGINT NOT NULL DEFAULT 0,
    s3_key          TEXT NOT NULL,
    category        TEXT NOT NULL DEFAULT 'other' CHECK (category IN ('document', 'image', 'training_material', 'other')),
    description     TEXT NOT NULL DEFAULT '',
    status          TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('draft', 'published')),
    published_at    TIMESTAMPTZ DEFAULT NOW(),
    created_by      TEXT NOT NULL DEFAULT '',
    updated_by      TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);
COMMENT ON TABLE cms.files IS 'Uploaded files for the file manager (documents, images, training materials)';

CREATE INDEX idx_cms_files_category ON cms.files (category) WHERE deleted_at IS NULL;
CREATE INDEX idx_cms_files_status ON cms.files (status) WHERE deleted_at IS NULL;

-- Project / product portfolio
CREATE TABLE cms.projects (
    id              TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    title_en        TEXT NOT NULL DEFAULT '',
    slug            TEXT NOT NULL,
    content         JSONB NOT NULL DEFAULT '{}',
    content_en      JSONB NOT NULL DEFAULT '{}',
    content_plain   TEXT NOT NULL DEFAULT '',
    content_plain_en TEXT NOT NULL DEFAULT '',
    summary         TEXT NOT NULL DEFAULT '',
    cover_image_url TEXT NOT NULL DEFAULT '',
    client_name     TEXT NOT NULL DEFAULT '',
    project_date    DATE,
    tags            TEXT[] NOT NULL DEFAULT '{}',
    sort_order      INT NOT NULL DEFAULT 0,
    is_featured     BOOLEAN NOT NULL DEFAULT FALSE,
    status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
    published_at    TIMESTAMPTZ,
    created_by      TEXT NOT NULL DEFAULT '',
    updated_by      TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);
COMMENT ON TABLE cms.projects IS 'Project and product portfolio entries';

CREATE UNIQUE INDEX idx_cms_projects_slug ON cms.projects (slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_cms_projects_sort_order ON cms.projects (sort_order);
CREATE INDEX idx_cms_projects_tags ON cms.projects USING gin(tags);
CREATE INDEX idx_cms_projects_featured ON cms.projects (is_featured) WHERE deleted_at IS NULL AND status = 'published';
CREATE INDEX idx_cms_projects_status ON cms.projects (status) WHERE deleted_at IS NULL;
CREATE INDEX idx_cms_projects_fts ON cms.projects USING gin(to_tsvector('simple', content_plain));
CREATE INDEX idx_cms_projects_fts_en ON cms.projects USING gin(to_tsvector('simple', content_plain_en));

-- Client / customer reviews
CREATE TABLE cms.reviews (
    id              TEXT PRIMARY KEY,
    client_name     TEXT NOT NULL,
    client_title    TEXT NOT NULL DEFAULT '',
    client_company  TEXT NOT NULL DEFAULT '',
    client_avatar_url TEXT NOT NULL DEFAULT '',
    testimonial     TEXT NOT NULL DEFAULT '',
    rating          INT NOT NULL DEFAULT 5 CHECK (rating >= 1 AND rating <= 5),
    is_featured     BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order      INT NOT NULL DEFAULT 0,
    status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
    published_at    TIMESTAMPTZ,
    created_by      TEXT NOT NULL DEFAULT '',
    updated_by      TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);
COMMENT ON TABLE cms.reviews IS 'Client testimonials and reviews';

CREATE INDEX idx_cms_reviews_sort_order ON cms.reviews (sort_order);
CREATE INDEX idx_cms_reviews_featured ON cms.reviews (is_featured) WHERE deleted_at IS NULL AND status = 'published';
CREATE INDEX idx_cms_reviews_status ON cms.reviews (status) WHERE deleted_at IS NULL;
