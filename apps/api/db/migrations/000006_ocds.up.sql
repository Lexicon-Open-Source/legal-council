-- Schema: ocds
-- Open Contracting Data Standard (OCDS) releases

CREATE SCHEMA IF NOT EXISTS ocds;

-- Releases: OCDS-formatted procurement releases
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
