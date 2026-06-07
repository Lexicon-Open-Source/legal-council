-- Restore NOT NULL on lat/lon (will fail if NULL rows exist — delete them first)
DELETE FROM geolocation.geocode_ocds WHERE lat IS NULL OR lon IS NULL;
ALTER TABLE geolocation.geocode_ocds ALTER COLUMN lat SET NOT NULL;
ALTER TABLE geolocation.geocode_ocds ALTER COLUMN lon SET NOT NULL;
