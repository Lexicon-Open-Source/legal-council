-- Schema: bo_crawler_v1
-- Web crawler data extraction and LLM processing

CREATE SCHEMA IF NOT EXISTS bo_crawler_v1;

-- URL Frontiers: URLs to be crawled
CREATE TABLE bo_crawler_v1.url_frontiers (
    id VARCHAR(64) NOT NULL,
    domain VARCHAR(255) NOT NULL,
    url VARCHAR(255) NOT NULL,
    crawler VARCHAR(255) NOT NULL,
    status SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    CONSTRAINT url_frontier_pkey PRIMARY KEY (id),
    CONSTRAINT url_frontier_unique UNIQUE (url)
);

CREATE INDEX idx_domain ON bo_crawler_v1.url_frontiers USING btree (domain);
CREATE INDEX idx_crawler ON bo_crawler_v1.url_frontiers USING btree (crawler);
CREATE INDEX idx_url ON bo_crawler_v1.url_frontiers USING btree (url);

-- Extractions: Raw content extracted from crawled pages
CREATE TABLE bo_crawler_v1.extractions (
    id VARCHAR(64) NOT NULL,
    url_frontier_id VARCHAR(64) NOT NULL,
    site_content TEXT,
    artifact_link VARCHAR(255),
    raw_page_link VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    language VARCHAR(10) NOT NULL DEFAULT 'en',
    metadata JSONB,
    CONSTRAINT extraction_pkey PRIMARY KEY (id)
);

-- LLM Extractions: AI-processed extraction results with embeddings
CREATE TABLE bo_crawler_v1.llm_extractions (
    id VARCHAR(36) NOT NULL DEFAULT (gen_random_uuid())::character varying,
    extraction_id VARCHAR NOT NULL,
    extraction_result JSONB,
    summary_en TEXT,
    summary_id TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    extraction_confidence DOUBLE PRECISION,
    content_embedding vector(768),
    summary_embedding_id vector(768),
    summary_embedding_en vector(768),
    embedding_generated BOOLEAN DEFAULT false,
    CONSTRAINT llm_extractions_pkey PRIMARY KEY (id),
    CONSTRAINT llm_extractions_unique UNIQUE (extraction_id)
);

CREATE INDEX idx_llm_extractions_extraction_id ON bo_crawler_v1.llm_extractions USING btree (extraction_id);
CREATE INDEX idx_llm_extractions_status ON bo_crawler_v1.llm_extractions USING btree (status);
CREATE INDEX ix_llm_extractions_result_gin ON bo_crawler_v1.llm_extractions USING gin (extraction_result);
CREATE INDEX ix_llm_extractions_embedding_generated ON bo_crawler_v1.llm_extractions USING btree (embedding_generated) WHERE (embedding_generated = false);

-- HNSW indexes for vector similarity search
CREATE INDEX ix_llm_extractions_content_hnsw ON bo_crawler_v1.llm_extractions USING hnsw (content_embedding vector_cosine_ops) WITH (m='16', ef_construction='64');
CREATE INDEX ix_llm_extractions_summary_id_hnsw ON bo_crawler_v1.llm_extractions USING hnsw (summary_embedding_id vector_cosine_ops) WITH (m='16', ef_construction='64');
CREATE INDEX ix_llm_extractions_summary_en_hnsw ON bo_crawler_v1.llm_extractions USING hnsw (summary_embedding_en vector_cosine_ops) WITH (m='16', ef_construction='64');
