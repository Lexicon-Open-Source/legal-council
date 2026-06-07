-- ============================================================
-- regulations: normative documents (laws, decrees, circulars)
-- ============================================================
CREATE TABLE entity_graph.regulations (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    jurisdiction    VARCHAR(10) NOT NULL,
    canonical_title TEXT NOT NULL,
    form            VARCHAR(100),
    number          VARCHAR(50),
    year            VARCHAR(10),
    subject         TEXT,
    status          VARCHAR(50),
    effective_date  DATE,
    properties      JSONB NOT NULL DEFAULT '{}',
    content_hash    TEXT NOT NULL,
    dataset         TEXT NOT NULL,
    source_table    TEXT NOT NULL,
    source_id       TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_jurisdiction CHECK (jurisdiction IN ('ID', 'SG', 'MY')),
    CONSTRAINT chk_regulation_status CHECK (status IN ('berlaku', 'tidak_berlaku', 'dicabut', 'diubah'))
);

COMMENT ON TABLE entity_graph.regulations IS 'Canonical regulation registry. One row per distinct regulation (law, decree, circular, etc.).';
COMMENT ON COLUMN entity_graph.regulations.jurisdiction IS 'ISO 3166-1 alpha-2: ID (Indonesia), SG (Singapore), MY (Malaysia)';
COMMENT ON COLUMN entity_graph.regulations.canonical_title IS 'Full official title of the regulation';
COMMENT ON COLUMN entity_graph.regulations.form IS 'Regulation form: undang-undang, peraturan_pemerintah, peraturan_presiden, etc. No CHECK — vocabulary varies by jurisdiction.';
COMMENT ON COLUMN entity_graph.regulations.status IS 'berlaku, tidak_berlaku, dicabut, diubah. Nullable — SG/MY may use different vocabulary.';
COMMENT ON COLUMN entity_graph.regulations.content_hash IS 'SHA256(dataset:sorted_key_props) — dedup key, UNIQUE index';
COMMENT ON COLUMN entity_graph.regulations.dataset IS 'Source dataset (jdih_bpk, peraturan_go_id, etc.)';
COMMENT ON COLUMN entity_graph.regulations.source_table IS 'Fully qualified source table (crawler.bpk_regulations, etc.)';
COMMENT ON COLUMN entity_graph.regulations.source_id IS 'ID in the source table (text, not FK — self-contained schema)';

CREATE UNIQUE INDEX idx_eg_regulations_content_hash ON entity_graph.regulations(content_hash);
CREATE INDEX idx_eg_regulations_jurisdiction ON entity_graph.regulations(jurisdiction);
CREATE INDEX idx_eg_regulations_form_number_year ON entity_graph.regulations(jurisdiction, form, number, year);
CREATE INDEX idx_eg_regulations_dataset ON entity_graph.regulations(dataset);
CREATE INDEX idx_eg_regulations_source ON entity_graph.regulations(source_table, source_id);
CREATE INDEX idx_eg_regulations_properties ON entity_graph.regulations USING gin(properties jsonb_path_ops);

CREATE TRIGGER set_regulations_updated_at
    BEFORE UPDATE ON entity_graph.regulations
    FOR EACH ROW EXECUTE FUNCTION entity_graph.trigger_set_timestamp();

-- ============================================================
-- regulation_content: full text + structured sections (1:1)
-- ============================================================
CREATE TABLE entity_graph.regulation_content (
    regulation_id   UUID NOT NULL PRIMARY KEY REFERENCES entity_graph.regulations(id) ON DELETE CASCADE,
    body_markdown   TEXT,
    sections        JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE entity_graph.regulation_content IS 'Full regulation text and structured sections. 1:1 with regulations. Separated to keep core table lean for graph traversal.';
COMMENT ON COLUMN entity_graph.regulation_content.body_markdown IS 'Full regulation body as markdown (converted from PDF/HTML). May be NULL if not yet extracted.';
COMMENT ON COLUMN entity_graph.regulation_content.sections IS 'Structured sections: {"menimbang": "...", "mengingat": "...", "memutuskan": "...", "toc": [...]}';

CREATE TRIGGER set_regulation_content_updated_at
    BEFORE UPDATE ON entity_graph.regulation_content
    FOR EACH ROW EXECUTE FUNCTION entity_graph.trigger_set_timestamp();

-- ============================================================
-- regulation_articles: pasal-level content for search (1:N)
-- ============================================================
CREATE TABLE entity_graph.regulation_articles (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    regulation_id   UUID NOT NULL REFERENCES entity_graph.regulations(id) ON DELETE CASCADE,
    bab             VARCHAR(10),
    bagian          VARCHAR(10),
    paragraf        VARCHAR(10),
    pasal           VARCHAR(10) NOT NULL,
    title           TEXT,
    content         TEXT NOT NULL,
    path            TEXT NOT NULL,
    ordinal         INT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE entity_graph.regulation_articles IS 'Pasal-level article content for BM25 full-text search. ~50 rows per regulation. One row per pasal — ayat text stays within the pasal content.';
COMMENT ON COLUMN entity_graph.regulation_articles.bab IS 'Chapter (BAB) number: I, II, III... For SG/MY: maps to Part.';
COMMENT ON COLUMN entity_graph.regulation_articles.bagian IS 'Part (Bagian) number within BAB. For SG/MY: maps to Division.';
COMMENT ON COLUMN entity_graph.regulation_articles.paragraf IS 'Paragraph (Paragraf) number within Bagian';
COMMENT ON COLUMN entity_graph.regulation_articles.pasal IS 'Article (Pasal) number: 1, 2, 3... For SG/MY: maps to Section.';
COMMENT ON COLUMN entity_graph.regulation_articles.content IS 'Full pasal text including all ayat. Ayat stay together — most citations reference pasal-level.';
COMMENT ON COLUMN entity_graph.regulation_articles.path IS 'Hierarchical path: BAB_I/Bagian_1/Pasal_7 — for display and ordering context';
COMMENT ON COLUMN entity_graph.regulation_articles.ordinal IS 'Position within the regulation document for ordered display';

CREATE UNIQUE INDEX idx_eg_regulation_articles_unique ON entity_graph.regulation_articles(regulation_id, path);
CREATE INDEX idx_eg_regulation_articles_regulation ON entity_graph.regulation_articles(regulation_id, ordinal);
CREATE INDEX idx_eg_regulation_articles_pasal ON entity_graph.regulation_articles(pasal);

-- ParadeDB BM25 index for full-text search at pasal level
-- Indexes content (article text), title (section title), pasal (article number) for relevance ranking
CREATE INDEX idx_eg_regulation_articles_bm25 ON entity_graph.regulation_articles
USING bm25 (id, content, title, pasal)
WITH (key_field='id');

-- ============================================================
-- regulation_identifiers: external IDs (mirrors actor_identifiers)
-- ============================================================
CREATE TABLE entity_graph.regulation_identifiers (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    regulation_id   UUID NOT NULL REFERENCES entity_graph.regulations(id) ON DELETE CASCADE,
    scheme          VARCHAR(50) NOT NULL,
    identifier      TEXT NOT NULL,
    dataset         TEXT NOT NULL
);

COMMENT ON TABLE entity_graph.regulation_identifiers IS 'External registry IDs per regulation. Multiple regulations may share (scheme, identifier) pre-merge.';
COMMENT ON COLUMN entity_graph.regulation_identifiers.scheme IS 'ID scheme: jdih_bpk_id, peraturan_go_id, etc.';

CREATE UNIQUE INDEX idx_eg_regulation_identifiers_unique ON entity_graph.regulation_identifiers(regulation_id, scheme, identifier);
CREATE INDEX idx_eg_regulation_identifiers_lookup ON entity_graph.regulation_identifiers(scheme, identifier);

-- ============================================================
-- event_regulations: event <-> regulation junction (verdict cites regulation)
-- ============================================================
CREATE TABLE entity_graph.event_regulations (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    event_id        UUID NOT NULL REFERENCES entity_graph.events(id) ON DELETE CASCADE,
    regulation_id   UUID NOT NULL REFERENCES entity_graph.regulations(id) ON DELETE CASCADE,
    role            VARCHAR(50) NOT NULL,
    article         TEXT,
    properties      JSONB NOT NULL DEFAULT '{}',
    dataset         TEXT NOT NULL,
    source_table    TEXT NOT NULL,
    source_id       TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_event_regulation_role CHECK (role IN ('legal_basis', 'proven_article', 'cited'))
);

COMMENT ON TABLE entity_graph.event_regulations IS 'Links events to regulations. Role describes the relationship: legal_basis, proven_article, cited.';
COMMENT ON COLUMN entity_graph.event_regulations.role IS 'legal_basis (law underpinning verdict), proven_article (specific article proven), cited (general citation)';
COMMENT ON COLUMN entity_graph.event_regulations.article IS 'Specific article/pasal reference (e.g., "Pasal 378")';

CREATE UNIQUE INDEX idx_eg_event_regulations_unique ON entity_graph.event_regulations(event_id, regulation_id, role, COALESCE(article, ''));
CREATE INDEX idx_eg_event_regulations_event ON entity_graph.event_regulations(event_id);
CREATE INDEX idx_eg_event_regulations_regulation ON entity_graph.event_regulations(regulation_id);

-- ============================================================
-- regulation_links: regulation <-> regulation (legislative history)
-- ============================================================
CREATE TABLE entity_graph.regulation_links (
    id                      UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    source_regulation_id    UUID NOT NULL REFERENCES entity_graph.regulations(id) ON DELETE CASCADE,
    target_regulation_id    UUID NOT NULL REFERENCES entity_graph.regulations(id) ON DELETE RESTRICT,
    link_type               VARCHAR(50) NOT NULL,
    properties              JSONB NOT NULL DEFAULT '{}',
    dataset                 TEXT NOT NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_regulation_link_type CHECK (link_type IN ('revokes', 'amends', 'amended_by', 'revoked_by', 'legal_basis')),
    CONSTRAINT chk_no_self_link CHECK (source_regulation_id != target_regulation_id)
);

COMMENT ON TABLE entity_graph.regulation_links IS 'Regulation-to-regulation relationships. Tracks legislative history and legal basis references (mengingat).';
COMMENT ON COLUMN entity_graph.regulation_links.link_type IS 'revokes, amends, amended_by, revoked_by, legal_basis (from mengingat section)';
COMMENT ON COLUMN entity_graph.regulation_links.source_regulation_id IS 'The regulation that performs the action (e.g., the regulation that revokes another)';
COMMENT ON COLUMN entity_graph.regulation_links.target_regulation_id IS 'The regulation being acted upon. ON DELETE RESTRICT — cannot delete a regulation referenced by legislative history.';

CREATE UNIQUE INDEX idx_eg_regulation_links_unique ON entity_graph.regulation_links(source_regulation_id, target_regulation_id, link_type);
CREATE INDEX idx_eg_regulation_links_source ON entity_graph.regulation_links(source_regulation_id);
CREATE INDEX idx_eg_regulation_links_target ON entity_graph.regulation_links(target_regulation_id);

-- ============================================================
-- actor_regulations: actor <-> regulation junction (issuer, enforcer)
-- ============================================================
CREATE TABLE entity_graph.actor_regulations (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    actor_id        UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE CASCADE,
    regulation_id   UUID NOT NULL REFERENCES entity_graph.regulations(id) ON DELETE CASCADE,
    role            VARCHAR(50) NOT NULL,
    dataset         TEXT NOT NULL,
    source_table    TEXT NOT NULL,
    source_id       TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_actor_regulation_role CHECK (role IN ('issuer', 'enforcer'))
);

COMMENT ON TABLE entity_graph.actor_regulations IS 'Links actors to regulations. Role describes the relationship: issuer (enacted by), enforcer (enforced by).';
COMMENT ON COLUMN entity_graph.actor_regulations.role IS 'issuer (public body that enacted the regulation), enforcer (body responsible for enforcement)';

CREATE UNIQUE INDEX idx_eg_actor_regulations_unique ON entity_graph.actor_regulations(actor_id, regulation_id, role);
CREATE INDEX idx_eg_actor_regulations_actor ON entity_graph.actor_regulations(actor_id);
CREATE INDEX idx_eg_actor_regulations_regulation ON entity_graph.actor_regulations(regulation_id);
