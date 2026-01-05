-- Clean up unused tables from PostgreSQL
-- Keep only: account_balance, transactions, transfers

-- Delete duplicate/unused tables
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS aggregate_versions CASCADE;
DROP TABLE IF EXISTS idempotency_keys CASCADE;
DROP TABLE IF EXISTS event_position CASCADE;

-- Verify remaining tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
