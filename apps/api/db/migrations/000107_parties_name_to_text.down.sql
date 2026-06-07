-- Revert: truncate data that exceeds 500 chars before ALTER.
-- Separate UPDATEs per column to avoid unnecessary writes on columns
-- that are already within the limit.
UPDATE ocds.parties SET name = LEFT(name, 500)
WHERE LENGTH(name) > 500;

UPDATE ocds.parties SET identifier_legal_name = LEFT(identifier_legal_name, 500)
WHERE LENGTH(identifier_legal_name) > 500;

UPDATE ocds.parties SET additional_identifier_legal_name = LEFT(additional_identifier_legal_name, 500)
WHERE LENGTH(additional_identifier_legal_name) > 500;

ALTER TABLE ocds.parties
    ALTER COLUMN name TYPE VARCHAR(500),
    ALTER COLUMN identifier_legal_name TYPE VARCHAR(500),
    ALTER COLUMN additional_identifier_legal_name TYPE VARCHAR(500);
