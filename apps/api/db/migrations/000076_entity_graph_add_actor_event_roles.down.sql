-- Restore original CHECK constraints

ALTER TABLE entity_graph.actor_events
    ADD CONSTRAINT chk_actor_events_role CHECK (role IN (
        'defendant', 'co_defendant', 'victim', 'witness',
        'judge', 'presiding_judge', 'prosecutor',
        'clerk', 'defense_counsel',
        'supplier', 'tenderer', 'winner', 'buyer',
        'subject', 'authority'
    ));

ALTER TABLE entity_graph.actor_links
    ADD CONSTRAINT chk_actor_links_type CHECK (link_type IN (
        'ownership', 'directorship', 'employment', 'family', 'associate'
    ));
