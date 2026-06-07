-- ============================================================
-- entity_graph schema
-- Normalized actors and events extracted from 12+ crawler sources.
-- Supports entity resolution (merge/split) and graph traversal.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS entity_graph;

-- Assert extension dependencies (idempotent, already installed in 000001)
CREATE EXTENSION IF NOT EXISTS pg_uuidv7;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Trigger function for updated_at (follows crawler schema pattern)
CREATE FUNCTION entity_graph.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Content-addressed hash for dedup at ingest
-- Keys are sorted internally to prevent ordering-dependent hashes
CREATE FUNCTION entity_graph.content_hash(p_dataset TEXT, p_keys TEXT[])
RETURNS TEXT AS $$
    SELECT encode(
        sha256(convert_to(
            p_dataset || ':' || array_to_string(
                ARRAY(SELECT coalesce(x, '__NULL__') FROM unnest(p_keys) AS x ORDER BY 1),
                ':'
            ),
            'UTF8'
        )),
        'hex'
    );
$$ LANGUAGE sql IMMUTABLE;

COMMENT ON FUNCTION entity_graph.content_hash IS
    'Deterministic dedup key: same entity from same source always produces the same hash. Keys are sorted internally. Used with INSERT ON CONFLICT.';

-- ============================================================
-- actors: persons, companies, organizations, public bodies
-- ============================================================

CREATE TABLE entity_graph.actors (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    actor_type      VARCHAR(50) NOT NULL,
    canonical_name  TEXT NOT NULL,
    name_normalized TEXT NOT NULL,
    properties      JSONB NOT NULL DEFAULT '{}',
    content_hash    TEXT NOT NULL,
    dataset         TEXT NOT NULL,
    source_table    TEXT,
    source_id       TEXT,
    is_merged       BOOLEAN NOT NULL DEFAULT FALSE,
    merged_into     UUID REFERENCES entity_graph.actors(id) ON DELETE RESTRICT,
    first_seen      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_actor_type CHECK (actor_type IN ('person', 'company', 'organization', 'public_body')),
    CONSTRAINT chk_actor_merge_consistency CHECK (
        (is_merged = TRUE AND merged_into IS NOT NULL) OR
        (is_merged = FALSE AND merged_into IS NULL)
    )
);

COMMENT ON TABLE entity_graph.actors IS 'Canonical actor registry. One row per real-world person, company, org.';
COMMENT ON COLUMN entity_graph.actors.actor_type IS 'person, company, organization, public_body. Professional roles (judge, prosecutor) are tracked via actor_events.role and properties JSONB.';
COMMENT ON COLUMN entity_graph.actors.content_hash IS 'SHA256(dataset:sorted_key_props) — dedup key, UNIQUE constraint';
COMMENT ON COLUMN entity_graph.actors.dataset IS 'Source dataset (interpol, lkpp, spse, mahkamah, etc.)';
COMMENT ON COLUMN entity_graph.actors.source_table IS 'Fully qualified source table (crawler.interpol_red_notices, etc.)';
COMMENT ON COLUMN entity_graph.actors.source_id IS 'ID in the source table (text, not FK — self-contained schema)';
COMMENT ON COLUMN entity_graph.actors.is_merged IS 'true if absorbed into another actor via entity resolution';
COMMENT ON COLUMN entity_graph.actors.merged_into IS 'FK to the winner actor. RESTRICT prevents deleting a winner while losers reference it. Use merge_decisions to reverse instead.';

CREATE UNIQUE INDEX idx_eg_actors_content_hash ON entity_graph.actors(content_hash);
CREATE INDEX idx_eg_actors_type ON entity_graph.actors(actor_type) WHERE NOT is_merged;
CREATE INDEX idx_eg_actors_name_trgm ON entity_graph.actors USING gin(name_normalized gin_trgm_ops) WHERE NOT is_merged;
CREATE INDEX idx_eg_actors_properties ON entity_graph.actors USING gin(properties jsonb_path_ops) WHERE NOT is_merged;
CREATE INDEX idx_eg_actors_dataset ON entity_graph.actors(dataset) WHERE NOT is_merged;
CREATE INDEX idx_eg_actors_merged_into ON entity_graph.actors(merged_into) WHERE is_merged;

CREATE TRIGGER set_actors_updated_at
    BEFORE UPDATE ON entity_graph.actors
    FOR EACH ROW EXECUTE FUNCTION entity_graph.trigger_set_timestamp();

-- ============================================================
-- actor_names: name variants for fuzzy search + blocking keys
-- ============================================================

CREATE TABLE entity_graph.actor_names (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    actor_id        UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    name_normalized TEXT NOT NULL,
    name_prefix3    VARCHAR(3),
    name_soundex    VARCHAR(10),
    lang            VARCHAR(10),
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
    dataset         TEXT NOT NULL,
    first_seen      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE entity_graph.actor_names IS 'All known name variants per actor. Used for fuzzy search and entity resolution blocking.';
COMMENT ON COLUMN entity_graph.actor_names.name_prefix3 IS 'First 3 chars of normalized name — blocking key for entity resolution';
COMMENT ON COLUMN entity_graph.actor_names.name_soundex IS 'Soundex of normalized name — blocking key for entity resolution';

CREATE INDEX idx_eg_actor_names_actor ON entity_graph.actor_names(actor_id);
CREATE INDEX idx_eg_actor_names_trgm ON entity_graph.actor_names USING gin(name_normalized gin_trgm_ops);
CREATE INDEX idx_eg_actor_names_prefix3 ON entity_graph.actor_names(name_prefix3);
CREATE INDEX idx_eg_actor_names_soundex ON entity_graph.actor_names(name_soundex);
-- Enforce at most one primary name per actor
CREATE UNIQUE INDEX idx_eg_actor_names_primary ON entity_graph.actor_names(actor_id) WHERE is_primary = TRUE;

-- ============================================================
-- actor_identifiers: registry IDs (NPWP, LKPP-ID, LEI, etc.)
-- ============================================================

CREATE TABLE entity_graph.actor_identifiers (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    actor_id        UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE CASCADE,
    scheme          VARCHAR(50) NOT NULL,
    identifier      TEXT NOT NULL,
    dataset         TEXT NOT NULL,
    first_seen      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE entity_graph.actor_identifiers IS 'External registry IDs. Multiple actors may share (scheme, identifier) pre-merge. Use lookup index for entity resolution candidate discovery.';
COMMENT ON COLUMN entity_graph.actor_identifiers.scheme IS 'ID scheme: npwp, lkpp_id, lei, nib, siup, passport, etc.';

-- Unique per actor: same actor cannot have two identical identifiers
CREATE UNIQUE INDEX idx_eg_actor_identifiers_actor_scheme ON entity_graph.actor_identifiers(actor_id, scheme, identifier);
-- Lookup index for entity resolution: find all actors sharing an identifier
CREATE INDEX idx_eg_actor_identifiers_lookup ON entity_graph.actor_identifiers(scheme, identifier);

-- ============================================================
-- events: verdicts, sanctions, blacklist entries, tenders
-- ============================================================

CREATE TABLE entity_graph.events (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    event_type      VARCHAR(50) NOT NULL,
    title           TEXT,
    properties      JSONB NOT NULL DEFAULT '{}',
    content_hash    TEXT NOT NULL,
    dataset         TEXT NOT NULL,
    source_table    TEXT,
    source_id       TEXT,
    event_date      DATE,
    first_seen      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_event_type CHECK (event_type IN ('verdict', 'sanction', 'blacklist_entry', 'tender'))
);

COMMENT ON TABLE entity_graph.events IS 'Time-bounded occurrences linked to actors. One row per distinct event.';
COMMENT ON COLUMN entity_graph.events.event_type IS 'verdict, sanction, blacklist_entry, tender';
COMMENT ON COLUMN entity_graph.events.title IS 'Human-readable event title (decision number, tender name, etc.)';
COMMENT ON COLUMN entity_graph.events.content_hash IS 'SHA256(dataset:sorted_key_props) — dedup key';

CREATE UNIQUE INDEX idx_eg_events_content_hash ON entity_graph.events(content_hash);
CREATE INDEX idx_eg_events_type_date ON entity_graph.events(event_type, event_date);
CREATE INDEX idx_eg_events_properties ON entity_graph.events USING gin(properties jsonb_path_ops);
CREATE INDEX idx_eg_events_dataset ON entity_graph.events(dataset);

CREATE TRIGGER set_events_updated_at
    BEFORE UPDATE ON entity_graph.events
    FOR EACH ROW EXECUTE FUNCTION entity_graph.trigger_set_timestamp();

-- ============================================================
-- actor_events: junction linking actors to events with role
-- ============================================================

CREATE TABLE entity_graph.actor_events (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    actor_id        UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE CASCADE,
    event_id        UUID NOT NULL REFERENCES entity_graph.events(id) ON DELETE CASCADE,
    role            VARCHAR(100) NOT NULL,
    dataset         TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_actor_events_role CHECK (role IN (
        'defendant', 'co_defendant', 'victim', 'witness',
        'judge', 'presiding_judge', 'prosecutor',
        'clerk', 'defense_counsel',
        'supplier', 'tenderer', 'winner', 'buyer',
        'subject', 'authority'
    ))
);

COMMENT ON TABLE entity_graph.actor_events IS 'Links actors to events. Role describes participation: defendant, judge, clerk, defense_counsel, supplier, subject, etc.';
COMMENT ON COLUMN entity_graph.actor_events.role IS 'defendant, co_defendant, victim, witness, judge, presiding_judge, prosecutor, clerk, defense_counsel, supplier, tenderer, winner, buyer, subject, authority';

CREATE UNIQUE INDEX idx_eg_actor_events_unique ON entity_graph.actor_events(actor_id, event_id, role);
CREATE INDEX idx_eg_actor_events_event_role ON entity_graph.actor_events(event_id, role);

-- ============================================================
-- actor_links: actor-to-actor relationships
-- ============================================================

CREATE TABLE entity_graph.actor_links (
    id              UUID NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
    link_type       VARCHAR(50) NOT NULL,
    source_actor_id UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE CASCADE,
    target_actor_id UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE CASCADE,
    properties      JSONB NOT NULL DEFAULT '{}',
    start_date      DATE,
    end_date        DATE,
    is_current      BOOLEAN NOT NULL DEFAULT TRUE,
    dataset         TEXT NOT NULL,
    first_seen      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_actor_links_type CHECK (link_type IN ('ownership', 'directorship', 'employment', 'family', 'associate')),
    CONSTRAINT chk_no_self_link CHECK (source_actor_id != target_actor_id)
);

COMMENT ON TABLE entity_graph.actor_links IS 'Actor-to-actor relationships. Enables ownership chains, directorship mapping, family links.';
COMMENT ON COLUMN entity_graph.actor_links.link_type IS 'ownership, directorship, employment, family, associate';
COMMENT ON COLUMN entity_graph.actor_links.properties IS '{"share_pct": 70.5, "role": "komisaris"} — link-type-specific attributes';
COMMENT ON COLUMN entity_graph.actor_links.is_current IS 'false if relationship has ended (end_date set)';

-- Composite indexes: (actor_id, link_type) enables "find all ownership links for actor X"
CREATE INDEX idx_eg_actor_links_source_type ON entity_graph.actor_links(source_actor_id, link_type);
CREATE INDEX idx_eg_actor_links_target_type ON entity_graph.actor_links(target_actor_id, link_type);
-- Includes COALESCE(start_date) to allow temporal re-opened relationships
CREATE UNIQUE INDEX idx_eg_actor_links_unique ON entity_graph.actor_links(
    source_actor_id, target_actor_id, link_type, dataset, COALESCE(start_date, '1970-01-01')
);

-- ============================================================
-- merge_decisions: entity resolution audit trail
-- ============================================================

CREATE TABLE entity_graph.merge_decisions (
    id              BIGSERIAL PRIMARY KEY,
    entity_a        UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE RESTRICT,
    entity_b        UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE RESTRICT,
    judgement        VARCHAR(20) NOT NULL,
    canonical_id    UUID REFERENCES entity_graph.actors(id) ON DELETE RESTRICT,
    score           NUMERIC(5,4),
    match_method    VARCHAR(50),
    decided_by      TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    decided_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reversed_at     TIMESTAMPTZ,
    reversed_by     TEXT,
    notes           TEXT,

    CONSTRAINT chk_merge_judgement CHECK (judgement IN ('positive', 'negative', 'unsure')),
    CONSTRAINT chk_merge_canonical_consistency CHECK (
        (judgement = 'positive' AND canonical_id IS NOT NULL) OR
        (judgement != 'positive' AND canonical_id IS NULL)
    ),
    CONSTRAINT chk_merge_score_range CHECK (score IS NULL OR (score >= 0 AND score <= 1)),
    CONSTRAINT chk_merge_entities_different CHECK (entity_a != entity_b)
);

COMMENT ON TABLE entity_graph.merge_decisions IS 'Audit trail for entity resolution. Records all merge/reject/unsure decisions. Actors referenced here cannot be hard-deleted (ON DELETE RESTRICT).';
COMMENT ON COLUMN entity_graph.merge_decisions.judgement IS 'positive (merge), negative (reject), unsure (queue for review)';
COMMENT ON COLUMN entity_graph.merge_decisions.canonical_id IS 'The winner entity ID (only set for positive judgements, enforced by CHECK)';
COMMENT ON COLUMN entity_graph.merge_decisions.match_method IS 'deterministic, fuzzy_name, fuzzy_identifier, manual';
COMMENT ON COLUMN entity_graph.merge_decisions.is_active IS 'false if merge was reversed (audit trail preserved)';
COMMENT ON COLUMN entity_graph.merge_decisions.reversed_at IS 'Timestamp when is_active was set to FALSE';
COMMENT ON COLUMN entity_graph.merge_decisions.reversed_by IS 'Operator or system that reversed the decision';

-- Symmetric unique constraint: prevents both (A,B) and (B,A) duplicates
CREATE UNIQUE INDEX idx_eg_merge_decisions_symmetric
    ON entity_graph.merge_decisions(LEAST(entity_a, entity_b), GREATEST(entity_a, entity_b))
    WHERE is_active = TRUE;

CREATE INDEX idx_eg_merge_decisions_entities ON entity_graph.merge_decisions(entity_a, entity_b);

-- ============================================================
-- watermarks: ETL progress tracking
-- ============================================================

CREATE TABLE entity_graph.watermarks (
    source_dataset  TEXT NOT NULL PRIMARY KEY,
    last_processed_at TIMESTAMPTZ,
    version         INT NOT NULL DEFAULT 0,
    status          VARCHAR(20) NOT NULL DEFAULT 'idle',
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_watermark_status CHECK (status IN ('idle', 'running', 'failed'))
);

COMMENT ON TABLE entity_graph.watermarks IS 'ETL progress tracking per source. Optimistic locking via version column.';
COMMENT ON COLUMN entity_graph.watermarks.version IS 'Optimistic lock: UPDATE SET version = version + 1 WHERE version = $expected';
COMMENT ON COLUMN entity_graph.watermarks.status IS 'idle, running, failed';
