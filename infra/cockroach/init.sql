-- CockroachDB Event Store Initialization

-- Create database
CREATE DATABASE IF NOT EXISTS chronicle;

-- Switch to chronicle database
SET DATABASE = chronicle;

-- ============================================
-- Events Table (Append-Only Event Log)
-- ============================================

CREATE TABLE IF NOT EXISTS events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_id VARCHAR(255) NOT NULL,
    aggregate_type VARCHAR(50) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL,
    event_version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by VARCHAR(255),
    metadata JSONB,
    
    -- Indexes for efficient queries
    INDEX idx_aggregate (aggregate_id, created_at DESC),
    INDEX idx_event_type (event_type, created_at DESC),
    INDEX idx_created_at (created_at DESC)
);

-- ============================================
-- Aggregate Versions (Optimistic Locking)
-- ============================================

CREATE TABLE IF NOT EXISTS aggregate_versions (
    aggregate_id VARCHAR(255) PRIMARY KEY,
    current_version INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Snapshots (Performance Optimization)
-- ============================================

CREATE TABLE IF NOT EXISTS snapshots (
    snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_id VARCHAR(255) NOT NULL,
    aggregate_type VARCHAR(50) NOT NULL,
    state_data JSONB NOT NULL,
    version INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    INDEX idx_snapshot_aggregate (aggregate_id, version DESC)
);

-- ============================================
-- Idempotency Keys (Prevent Duplicate Writes)
-- ============================================

CREATE TABLE IF NOT EXISTS idempotency_keys (
    key UUID PRIMARY KEY,
    response JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours')
);


