-- Rollback: Restore original OCDS schema with JSONB

-- Drop new tables in reverse order (respecting foreign keys)
DROP TABLE IF EXISTS ocds.transformation_log CASCADE;
DROP TABLE IF EXISTS ocds.milestones CASCADE;
DROP TABLE IF EXISTS ocds.documents CASCADE;
DROP TABLE IF EXISTS ocds.items CASCADE;
DROP TABLE IF EXISTS ocds.planning CASCADE;
DROP TABLE IF EXISTS ocds.contracts CASCADE;
DROP TABLE IF EXISTS ocds.award_suppliers CASCADE;
DROP TABLE IF EXISTS ocds.awards CASCADE;
DROP TABLE IF EXISTS ocds.tender_tenderers CASCADE;
DROP TABLE IF EXISTS ocds.tender CASCADE;
DROP TABLE IF EXISTS ocds.releases CASCADE;
DROP TABLE IF EXISTS ocds.parties CASCADE;

-- Restore original releases table
CREATE TABLE ocds.releases (
    id SERIAL NOT NULL,
    ocid VARCHAR(100) NOT NULL,
    release_id VARCHAR(150) NOT NULL,
    date TIMESTAMPTZ NOT NULL,
    tag TEXT[] NOT NULL,
    release JSONB NOT NULL,
    source_tender_id INTEGER NOT NULL,
    source_updated_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT releases_pkey PRIMARY KEY (id),
    CONSTRAINT releases_ocid_release_id_key UNIQUE (ocid, release_id)
);

CREATE INDEX idx_releases_ocid ON ocds.releases USING btree (ocid);
CREATE INDEX idx_releases_jsonb ON ocds.releases USING gin (release jsonb_path_ops);
