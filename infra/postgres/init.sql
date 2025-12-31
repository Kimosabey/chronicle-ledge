-- PostgreSQL Read Model Initialization

-- ============================================
-- Account Balance (Materialized View)
-- ============================================

CREATE TABLE IF NOT EXISTS account_balance (
    account_id VARCHAR(255) PRIMARY KEY,
    owner_name VARCHAR(255) NOT NULL,
    balance NUMERIC(20, 2) NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    
    CHECK (balance >= 0)  -- No overdrafts
);

CREATE INDEX IF NOT EXISTS idx_account_status ON account_balance(status);
CREATE INDEX IF NOT EXISTS idx_account_created ON account_balance(created_at DESC);

-- ============================================
-- Transaction History (Denormalized)
-- ============================================

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id UUID PRIMARY KEY,
    account_id VARCHAR(255) NOT NULL REFERENCES account_balance(account_id),
    type VARCHAR(50) NOT NULL,  -- deposit, withdrawal, transfer_in, transfer_out
    amount NUMERIC(20, 2) NOT NULL,
    balance_after NUMERIC(20, 2) NOT NULL,
    description TEXT,
    timestamp TIMESTAMPTZ NOT NULL,
    
    CHECK (amount > 0)
);

CREATE INDEX IF NOT EXISTS idx_account_transactions ON transactions(account_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_transaction_type ON transactions(type, timestamp DESC);

-- ============================================
-- Transfers (Link Transfer Pairs)
-- ============================================

CREATE TABLE IF NOT EXISTS transfers (
    transfer_id UUID PRIMARY KEY,
    from_account_id VARCHAR(255) NOT NULL,
    to_account_id VARCHAR(255) NOT NULL,
    amount NUMERIC(20, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,  -- pending, completed, failed
    timestamp TIMESTAMPTZ NOT NULL,
    
    CHECK (from_account_id != to_account_id),
    CHECK (amount > 0)
);

CREATE INDEX IF NOT EXISTS idx_from_account ON transfers(from_account_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_to_account ON transfers(to_account_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_transfer_status ON transfers(status);

-- ============================================
-- Materialization Tracking
-- ============================================

CREATE TABLE IF NOT EXISTS event_position (
    processor_name VARCHAR(100) PRIMARY KEY,
    last_event_id UUID NOT NULL,
    last_processed_at TIMESTAMPTZ DEFAULT NOW()
);

COMMIT;
