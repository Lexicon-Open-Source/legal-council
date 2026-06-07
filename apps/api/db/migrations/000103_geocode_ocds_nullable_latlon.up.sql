-- Allow NULL lat/lon in geocode_ocds for negative cache entries.
-- When a geocode query returns no results, we still create a geocode_ocds row
-- (with NULL lat/lon) to prevent the item from appearing as "pending" forever.

ALTER TABLE geolocation.geocode_ocds ALTER COLUMN lat DROP NOT NULL;
ALTER TABLE geolocation.geocode_ocds ALTER COLUMN lon DROP NOT NULL;
