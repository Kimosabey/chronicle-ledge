# Database Tables Usage Documentation

## CockroachDB (`chronicle` database on port 26257)

### ✅ **USED TABLES**

#### 1. `events` (PRIMARY - EVENT STORE)
**Purpose:** Immutable event log - Source of truth for all state changes

**Columns:**
- `event_id` UUID - Unique identifier
- `aggregate_id` VARCHAR - Entity ID (account ID)
- `event_type` VARCHAR - Type of event (AccountCreated, MoneyDeposited, etc.)
- `event_data` JSONB - Event payload
- `created_at` TIMESTAMPTZ - When event occurred
- `aggregate_version` INT - Version number for optimistic locking

**Usage:** Written by Ledger API, Read by Query API for time-travel queries

**Current Data:** 16 events ✅

---

### ⚪ **UNUSED TABLES** (Created but not implemented yet)

#### 2. `aggregate_versions`
**Purpose:** Track current version of each aggregate for optimistic locking
**Status:** Not implemented - versions tracked in events table instead
**Current Data:** 0 rows

#### 3. `idempotency_keys`
**Purpose:** Prevent duplicate command processing
**Status:** Not implemented - would store processed command IDs
**Current Data:** 0 rows

#### 4. `snapshots`
**Purpose:** Store aggregate snapshots for performance optimization
**Status:** Not implemented - using event replay instead
**Current Data:** 0 rows

---

## PostgreSQL (`chronicle` database on port 5433)

### ✅ **USED TABLES**

#### 1. `account_balance` (PRIMARY - READ MODEL)
**Purpose:** Current state of all accounts (materialized view)

**Columns:**
- `account_id` VARCHAR PRIMARY KEY
- `owner_name` VARCHAR
- `balance` DECIMAL(18,2)
- `currency` VARCHAR(3)
- `status` VARCHAR (active/suspended/closed)
- `created_at` TIMESTAMPTZ
- `last_updated` TIMESTAMPTZ

**Usage:** Updated by Read Processor when events are consumed from NATS

**Current Data:** 6 accounts ✅

---

### ⚪ **PARTIALLY USED TABLES**

#### 2. `transactions`
**Purpose:** Transaction history for each account

**Columns:**
- `transaction_id` UUID PRIMARY KEY
- `account_id` VARCHAR (FK to account_balance)
- `transaction_type` VARCHAR (deposit/withdrawal/transfer)
- `amount` DECIMAL(18,2)
- `balance_after` DECIMAL(18,2)
- `description` TEXT
- `created_at` TIMESTAMPTZ

**Usage:** Should be populated by Read Processor alongside account_balance updates

**Current Data:** 0 rows ⚠️ **NOT BEING POPULATED YET**

**Action Required:** Update Read Processor to insert transaction records when processing MoneyDeposited/MoneyWithdrawn events

---

#### 3. `transfers`
**Purpose:** Track transfers between accounts

**Columns:**
- `transfer_id` UUID PRIMARY KEY
-from_account_id` VARCHAR
- `to_account_id` VARCHAR
- `amount` DECIMAL(18,2)
- `description` TEXT
- `status` VARCHAR (pending/completed/failed)
- `created_at` TIMESTAMPTZ

**Usage:** Should be populated when processing transfer events

**Current Data:** 0 rows ⚠️ **NOT BEING POPULATED YET**

**Action Required:** Update Read Processor to insert transfer records when processing Transfer events

---

### ⚪ **UNUSED TABLES**

#### 4. `events` (NOT USED)
**Purpose:** Duplicate of CockroachDB events table
**Status:** Not used - events stored in CockroachDB only
**Current Data:** 0 rows ✅ (Correct - intentionally empty)

#### 5. `aggregate_versions` (NOT USED)
**Purpose:** Same as CockroachDB version
**Status:** Not implemented
**Current Data:** 0 rows

#### 6. `event_position` (NOT USED)
**Purpose:** Track read processor position in event stream
**Status:** Not implemented - processor reads all events each time
**Current Data:** 0 rows

#### 7. `idempotency_keys` (NOT USED)
**Purpose:** Same as CockroachDB version
**Status:** Not implemented
**Current Data:** 0 rows

---

## 📊 **Summary**

### Currently Working:
1. ✅ CockroachDB `events` → Event Store (16 events)
2. ✅ PostgreSQL `account_balance` → Read Model (6 accounts)

### Needs Implementation:
1. ⚠️ PostgreSQL `transactions` → Should record each deposit/withdrawal
2. ⚠️ PostgreSQL `transfers` → Should record each transfer

### Not Needed (Can be deleted):
1. ❌ PostgreSQL `events` → Duplicate, use CockroachDB instead
2. ❌ Both `aggregate_versions` tables → If not implementing optimistic locking
3. ❌ Both `idempotency_keys` tables → If not implementing idempotency
4. ❌ CockroachDB `snapshots` → If relying on event replay

---

## 🔧 **Recommended Actions**

### 1. Implement Missing Features (Priority)

**Update Read Processor** (`services/read-processor/src/index.ts`):

Add transaction recording when processing events:

```typescript
// After updating account_balance, also insert transaction:
if (event.event_type === 'MoneyDeposited') {
  // Update account balance (existing code)
  await updateAccountBalance(event.aggregate_id, data.amount);
  
  // Insert transaction record (NEW)
  await query(`
    INSERT INTO transactions (transaction_id, account_id, transaction_type, amount, balance_after, description, created_at)
    VALUES ($1, $2, 'deposit', $3, (SELECT balance FROM account_balance WHERE account_id = $2), $4, $5)
  `, [uuidv4(), event.aggregate_id, data.amount, data.description, event.created_at]);
}
```

**Add transfer tracking:**

```typescript
if (event.event_type.includes('Transfer')) {
  await query(`
    INSERT INTO transfers (transfer_id, from_account_id, to_account_id, amount, description, status, created_at)
    VALUES ($1, $2, $3, $4, $5, 'completed', $6)
  `, [data.transfer_id, data.from_account_id, data.to_account_id, data.amount, data.description, event.created_at]);
}
```

---

### 2. Clean Up Unused Tables (Optional)

If features won't be implemented, remove unused tables to reduce confusion:

**CockroachDB:**
```sql
DROP TABLE IF EXISTS aggregate_versions;
DROP TABLE IF EXISTS idempotency_keys;
DROP TABLE IF EXISTS snapshots;
```

**PostgreSQL:**
```sql
DROP TABLE IF EXISTS events;  -- Not used, events in CockroachDB
DROP TABLE IF EXISTS aggregate_versions;
DROP TABLE IF EXISTS idempotency_keys;
DROP TABLE IF EXISTS event_position;
```

---

## 🎯 **Final Recommended Structure**

### CockroachDB (Event Store)
- `events` ← KEEP (primary event log)

### PostgreSQL (Read Model)
- `account_balance` ← KEEP (current accounts)
- `transactions` ← KEEP & POPULATE (transaction history)
- `transfers` ← KEEP & POPULATE (transfer tracking)

**Total: 4 tables, all actively used**
