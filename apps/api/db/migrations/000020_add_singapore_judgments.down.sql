-- Rollback: Drop Singapore judgments table
DROP TRIGGER IF EXISTS update_sg_judgments_updated_at ON crawler.singapore_judgments;
DROP TABLE IF EXISTS crawler.singapore_judgments;
