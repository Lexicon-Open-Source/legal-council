-- Drop rigid enum-style CHECK constraints on actor_events.role and
-- actor_links.link_type. New crawler sources introduce new values
-- frequently, making hardcoded CHECKs impractical to maintain.
--
-- Known actor_events.role values:
--   defendant, co_defendant, victim, witness, judge, presiding_judge,
--   prosecutor, clerk, defense_counsel, supplier, tenderer, winner,
--   buyer, subject, authority, sanctioned, blacklisted, issuer
--
-- Known actor_links.link_type values:
--   ownership, directorship, employment, family, associate

ALTER TABLE entity_graph.actor_events
    DROP CONSTRAINT IF EXISTS chk_actor_events_role;

ALTER TABLE entity_graph.actor_links
    DROP CONSTRAINT IF EXISTS chk_actor_links_type;
