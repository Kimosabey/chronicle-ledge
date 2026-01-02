# 🔧 Low-Level Design (LLD)
## ChronicleLedger - API Contracts & Data Models

---

## 📋 Table of Contents
1. [Database Schemas](#database-schemas)
2. [API Contracts](#api-contracts)
3. [Event Definitions](#event-definitions)
4. [Data Models](#data-models)
5. [Error Handling](#error-handling)
6. [Validation Rules](#validation-rules)

---

![API Reference](./images/api-reference.png)
*Complete API Endpoint Map - Commands & Queries*

## 1. Database Schemas

### 1.1 CockroachDB Event Store

```sql
-- Main events table (append-only)
CREATE TABLE events (
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

-- Optimistic locking for concurrent writes (optional)
CREATE TABLE aggregate_versions (
    aggregate_id VARCHAR(255) PRIMARY KEY,
    current_version INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- Snapshots table (for performance optimization)
CREATE TABLE snapshots (
    snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_id VARCHAR(255) NOT NULL,
    aggregate_type VARCHAR(50) NOT NULL,
    state_data JSONB NOT NULL,
    version INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    INDEX idx_snapshot_aggregate (aggregate_id, version DESC)
);
```

---

### 1.2 PostgreSQL Read Model

```sql
-- Account balances (materialized view)
CREATE TABLE account_balance (
    account_id VARCHAR(255) PRIMARY KEY,
    owner_name VARCHAR(255) NOT NULL,
    balance NUMERIC(20, 2) NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    
    CHECK (balance >= 0)  -- No overdrafts
);

-- Transaction history (denormalized for fast queries)
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY,
    account_id VARCHAR(255) NOT NULL REFERENCES account_balance(account_id),
    type VARCHAR(50) NOT NULL,  -- 'deposit', 'withdrawal', 'transfer_in', 'transfer_out'
    amount NUMERIC(20, 2) NOT NULL,
    balance_after NUMERIC(20, 2) NOT NULL,
    description TEXT,
    timestamp TIMESTAMPTZ NOT NULL,
    
    INDEX idx_account_transactions (account_id, timestamp DESC)
);

-- Transfer pairs (for linking transfers)
CREATE TABLE transfers (
    transfer_id UUID PRIMARY KEY,
    from_account_id VARCHAR(255) NOT NULL,
    to_account_id VARCHAR(255) NOT NULL,
    amount NUMERIC(20, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,  -- 'pending', 'completed', 'failed'
    timestamp TIMESTAMPTZ NOT NULL,
    
    INDEX idx_from_account (from_account_id, timestamp DESC),
    INDEX idx_to_account (to_account_id, timestamp DESC)
);
```

---

## 2. API Contracts

### 2.1 Ledger API (Write Service)

**Base URL**: `http://localhost:4000/api/v1`

#### POST `/commands/create-account`

**Purpose**: Create a new account

**Request:**
```json
{
  "account_id": "ACC-001",
  "owner_name": "John Doe",
  "initial_balance": 1000.00,
  "currency": "USD"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "aggregate_id": "account:ACC-001",
  "timestamp": "2026-01-15T10:30:00Z"
}
```

**Errors:**
- `400` - Account ID already exists
- `422` - Invalid input (negative balance, invalid currency)

---

#### POST `/commands/deposit`

**Purpose**: Deposit money into an account

**Request:**
```json
{
  "account_id": "ACC-001",
  "amount": 500.00,
  "description": "Salary payment"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "event_id": "660e8400-e29b-41d4-a716-446655440001",
  "aggregate_id": "account:ACC-001",
  "balance_after": 1500.00,
  "timestamp": "2026-01-15T10:35:00Z"
}
```

**Errors:**
- `404` - Account not found
- `422` - Invalid amount (≤ 0)

---

#### POST `/commands/withdraw`

**Purpose**: Withdraw money from an account

**Request:**
```json
{
  "account_id": "ACC-001",
  "amount": 200.00,
  "description": "ATM withdrawal"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "event_id": "770e8400-e29b-41d4-a716-446655440002",
  "aggregate_id": "account:ACC-001",
  "balance_after": 1300.00,
  "timestamp": "2026-01-15T10:40:00Z"
}
```

**Errors:**
- `404` - Account not found
- `422` - Insufficient funds
- `422` - Invalid amount (≤ 0)

---

#### POST `/commands/transfer`

**Purpose**: Transfer money between accounts (distributed saga)

**Request:**
```json
{
  "from_account_id": "ACC-001",
  "to_account_id": "ACC-002",
  "amount": 300.00,
  "description": "Loan repayment"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "transfer_id": "880e8400-e29b-41d4-a716-446655440003",
  "events": [
    {
      "event_id": "990e8400-e29b-41d4-a716-446655440004",
      "aggregate_id": "account:ACC-001",
      "event_type": "MoneyWithdrawn"
    },
    {
      "event_id": "aa0e8400-e29b-41d4-a716-446655440005",
      "aggregate_id": "account:ACC-002",
      "event_type": "MoneyDeposited"
    }
  ],
  "timestamp": "2026-01-15T10:45:00Z"
}
```

**Errors:**
- `404` - From/To account not found
- `422` - Insufficient funds
- `422` - Cannot transfer to same account

---

### 2.2 Query API (Read Service)

**Base URL**: `http://localhost:4001/api/v1`

#### GET `/accounts/:id/balance`

**Purpose**: Get current account balance (fast query from read model)

**Response (200 OK):**
```json
{
  "account_id": "ACC-001",
  "owner_name": "John Doe",
  "balance": 1300.00,
  "currency": "USD",
  "status": "active",
  "last_updated": "2026-01-15T10:40:00Z"
}
```

**Errors:**
- `404` - Account not found

---

#### GET `/accounts/:id/history`

**Purpose**: Get complete event history for audit (query from event store)

**Query Parameters:**
- `from` - Start timestamp (ISO 8601)
- `to` - End timestamp (ISO 8601)
- `limit` - Max events (default: 100)

**Response (200 OK):**
```json
{
  "account_id": "ACC-001",
  "events": [
    {
      "event_id": "550e8400-e29b-41d4-a716-446655440000",
      "event_type": "AccountCreated",
      "event_data": {
        "owner_name": "John Doe",
        "initial_balance": 1000.00,
        "currency": "USD"
      },
      "created_at": "2026-01-15T10:30:00Z",
      "created_by": "system"
    },
    {
      "event_id": "660e8400-e29b-41d4-a716-446655440001",
      "event_type": "MoneyDeposited",
      "event_data": {
        "amount": 500.00,
        "description": "Salary payment"
      },
      "created_at": "2026-01-15T10:35:00Z",
      "created_by": "user:123"
    },
    {
      "event_id": "770e8400-e29b-41d4-a716-446655440002",
      "event_type": "MoneyWithdrawn",
      "event_data": {
        "amount": 200.00,
        "description": "ATM withdrawal"
      },
      "created_at": "2026-01-15T10:40:00Z",
      "created_by": "user:123"
    }
  ],
  "total_events": 3,
  "current_balance": 1300.00
}
```

---

#### GET `/accounts/:id/balance?at=<timestamp>`

**Purpose**: Time-travel query (balance at specific point in time)

**Example**: `GET /accounts/ACC-001/balance?at=2026-01-15T10:35:00Z`

**Response (200 OK):**
```json
{
  "account_id": "ACC-001",
  "balance": 1500.00,
  "timestamp": "2026-01-15T10:35:00Z",
  "reconstructed_from_events": true
}
```

---

#### GET `/transactions`

**Purpose**: Query transaction history with filters

**Query Parameters:**
- `account_id` - Filter by account
- `type` - Filter by transaction type
- `from` - Start timestamp
- `to` - End timestamp
- `limit` - Max results (default: 50)
- `offset` - Pagination offset

**Response (200 OK):**
```json
{
  "transactions": [
    {
      "transaction_id": "660e8400-e29b-41d4-a716-446655440001",
      "account_id": "ACC-001",
      "type": "deposit",
      "amount": 500.00,
      "balance_after": 1500.00,
      "description": "Salary payment",
      "timestamp": "2026-01-15T10:35:00Z"
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

---

## 3. Event Definitions

### Event Structure (Standard)

```typescript
interface Event {
  event_id: string;          // UUID
  aggregate_id: string;      // e.g., "account:ACC-001"
  aggregate_type: string;    // e.g., "Account"
  event_type: string;        // e.g., "MoneyDeposited"
  event_data: object;        // Event-specific payload
  event_version: number;     // Schema version (default: 1)
  created_at: string;        // ISO 8601 timestamp
  created_by: string;        // User/System ID
  metadata?: object;         // Optional (correlation_id, ip, etc.)
}
```

---

### 3.1 AccountCreated (v1)

```json
{
  "event_type": "AccountCreated",
  "event_data": {
    "account_id": "ACC-001",
    "owner_name": "John Doe",
    "initial_balance": 1000.00,
    "currency": "USD"
  }
}
```

---

### 3.2 MoneyDeposited (v1)

```json
{
  "event_type": "MoneyDeposited",
  "event_data": {
    "amount": 500.00,
    "balance_after": 1500.00,
    "description": "Salary payment"
  }
}
```

---

### 3.3 MoneyWithdrawn (v1)

```json
{
  "event_type": "MoneyWithdrawn",
  "event_data": {
    "amount": 200.00,
    "balance_after": 1300.00,
    "description": "ATM withdrawal"
  }
}
```

---

### 3.4 TransferInitiated (v1)

```json
{
  "event_type": "TransferInitiated",
  "event_data": {
    "transfer_id": "TXN-12345",
    "from_account_id": "ACC-001",
    "to_account_id": "ACC-002",
    "amount": 300.00
  }
}
```

---

### 3.5 TransferCompleted (v1)

```json
{
  "event_type": "TransferCompleted",
  "event_data": {
    "transfer_id": "TXN-12345",
    "status": "completed"
  }
}
```

---

### 3.6 TransferFailed (v1)

```json
{
  "event_type": "TransferFailed",
  "event_data": {
    "transfer_id": "TXN-12345",
    "reason": "Insufficient funds",
    "status": "failed"
  }
}
```

---

## 4. Data Models (TypeScript)

### 4.1 Domain Models

```typescript
// Account aggregate
interface Account {
  id: string;
  ownerName: string;
  balance: number;
  currency: string;
  status: 'active' | 'suspended' | 'closed';
  createdAt: Date;
  version: number;
}

// Command models
interface CreateAccountCommand {
  accountId: string;
  ownerName: string;
  initialBalance: number;
  currency: string;
}

interface DepositCommand {
  accountId: string;
  amount: number;
  description?: string;
}

interface WithdrawCommand {
  accountId: string;
  amount: number;
  description?: string;
}

interface TransferCommand {
  fromAccountId: string;
  toAccountId: string;
  amount: number;
  description?: string;
}
```

---

### 4.2 Event Models

```typescript
interface BaseEvent {
  eventId: string;
  aggregateId: string;
  aggregateType: string;
  eventType: string;
  eventVersion: number;
  createdAt: Date;
  createdBy: string;
  metadata?: Record<string, any>;
}

interface AccountCreatedEvent extends BaseEvent {
  eventType: 'AccountCreated';
  eventData: {
    accountId: string;
    ownerName: string;
    initialBalance: number;
    currency: string;
  };
}

interface MoneyDepositedEvent extends BaseEvent {
  eventType: 'MoneyDeposited';
  eventData: {
    amount: number;
    balanceAfter: number;
    description?: string;
  };
}

interface MoneyWithdrawnEvent extends BaseEvent {
  eventType: 'MoneyWithdrawn';
  eventData: {
    amount: number;
    balanceAfter: number;
    description?: string;
  };
}
```

---

## 5. Error Handling

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_FUNDS",
    "message": "Account balance (500.00) is insufficient for withdrawal (700.00)",
    "timestamp": "2026-01-15T10:50:00Z",
    "request_id": "req-12345"
  }
}
```

### Error Codes

| Code                     | HTTP Status | Description                     |
| ------------------------ | ----------- | ------------------------------- |
| `ACCOUNT_NOT_FOUND`      | 404         | Account ID does not exist       |
| `ACCOUNT_ALREADY_EXISTS` | 400         | Account ID already in use       |
| `INSUFFICIENT_FUNDS`     | 422         | Balance too low for withdrawal  |
| `INVALID_AMOUNT`         | 422         | Amount must be > 0              |
| `INVALID_CURRENCY`       | 422         | Currency not supported          |
| `ACCOUNT_SUSPENDED`      | 403         | Account is suspended            |
| `TRANSFER_TO_SELF`       | 422         | Cannot transfer to same account |
| `INTERNAL_ERROR`         | 500         | Unexpected server error         |

---

## 6. Validation Rules

### Account ID
- Pattern: `^[A-Z]{3}-[0-9]{3,6}$`
- Example: `ACC-001`, `SAV-123456`

### Amount
- Must be > 0
- Max precision: 2 decimal places
- Max value: 999,999,999.99

### Currency
- ISO 4217 codes: `USD`, `EUR`, `GBP`, `INR`

### Owner Name
- Min length: 2 characters
- Max length: 255 characters
- Pattern: `^[a-zA-Z\s]+$` (letters and spaces only)

---

## 7. NATS Subject Design

```
events.account.created         → AccountCreated events
events.account.deposited       → MoneyDeposited events
events.account.withdrawn       → MoneyWithdrawn events
events.transfer.initiated      → TransferInitiated events
events.transfer.completed      → TransferCompleted events
events.transfer.failed         → TransferFailed events
```

**Subscription Patterns:**
```
events.account.*     → All account events
events.transfer.*    → All transfer events
events.*.*           → All events (audit logger)
```

---

## 8. Rate Limiting

**Ledger API:**
- Per IP: 100 requests/minute
- Per Account: 50 writes/minute

**Query API:**
- Per IP: 1000 requests/minute

**Implementation**: Redis + Token Bucket Algorithm

---

## 9. Idempotency

**Problem**: Network retries may cause duplicate writes

**Solution**: Idempotency key in request header

```http
POST /commands/deposit
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000

{
  "account_id": "ACC-001",
  "amount": 500.00
}
```

**Implementation:**
```sql
CREATE TABLE idempotency_keys (
    key UUID PRIMARY KEY,
    response JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours'
);
```

If key exists, return cached response (200 OK) instead of 201 Created.

---

## 10. Authentication & Authorization

**Phase 1 (MVP)**: API Key in header
```http
Authorization: Bearer sk_test_12345
```

**Phase 2**: JWT with RBAC
```json
{
  "user_id": "user:123",
  "roles": ["account_owner", "admin"],
  "permissions": ["read:balance", "write:deposit"]
}
```

---

**Next Steps**: See [FAILURE_SCENARIOS.md](./FAILURE_SCENARIOS.md) for chaos testing guide.
