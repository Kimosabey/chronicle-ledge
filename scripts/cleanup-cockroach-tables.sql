-- Clean up unused tables from CockroachDB
-- Keep only: events (event store)

-- Delete optional/unused tables
DROP TABLE IF EXISTS aggregate_versions CASCADE;
DROP TABLE IF EXISTS idempotency_keys CASCADE;
DROP TABLE IF EXISTS snapshots CASCADE;

-- Verify remaining tables
SHOW TABLES FROM chronicle;
