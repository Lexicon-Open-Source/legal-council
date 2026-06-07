-- Drop in reverse dependency order (children before parents, junction tables first)
DROP TABLE IF EXISTS entity_graph.actor_regulations;

-- regulation_links: must drop before regulations due to ON DELETE RESTRICT on target
DROP TABLE IF EXISTS entity_graph.regulation_links;

DROP TABLE IF EXISTS entity_graph.event_regulations;

-- Explicitly drop BM25 index before table (ParadeDB extension index safety)
DROP INDEX IF EXISTS entity_graph.idx_eg_regulation_articles_bm25;
DROP TABLE IF EXISTS entity_graph.regulation_articles;

DROP TABLE IF EXISTS entity_graph.regulation_content;
DROP TABLE IF EXISTS entity_graph.regulation_identifiers;
DROP TABLE IF EXISTS entity_graph.regulations;
