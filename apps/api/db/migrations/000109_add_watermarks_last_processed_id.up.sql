-- Migration: Add last_processed_id column to entity_graph.watermarks
-- Purpose: Enable composite cursor pagination (updated_at, id) to handle
-- bulk-inserted rows with identical timestamps that exceed BATCH_SIZE.
--
-- This migration MUST be applied BEFORE deploying the updated Python code.
-- The new code references this column in claim_watermark() RETURNING clause.
--
-- Safe to run multiple times (IF NOT EXISTS).

ALTER TABLE entity_graph.watermarks
    ADD COLUMN IF NOT EXISTS last_processed_id TEXT
    DEFAULT '00000000-0000-0000-0000-000000000000';
