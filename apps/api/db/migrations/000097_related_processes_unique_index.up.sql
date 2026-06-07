-- Enable ON CONFLICT DO NOTHING for relatedProcesses deduplication
CREATE UNIQUE INDEX IF NOT EXISTS idx_related_processes_release_identifier
  ON ocds.related_processes(release_id, identifier);
