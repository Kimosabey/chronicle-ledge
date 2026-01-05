# 📊 Where to See Your Data - Quick Reference

## 🎯 Overview

Your Chronicle Ledger uses **two databases** for different purposes:

| Database        | Purpose             | What to Check                     |
| --------------- | ------------------- | --------------------------------- |
| **CockroachDB** | Event Store (Write) | `events` table                    |
| **PostgreSQL**  | Read Model (Query)  | `account_balance`, `transactions` |

---

## 1️⃣ CockroachDB - Event Store

### Web UI (Recommended)
**URL:** http://localhost:8080

**Navigation:**
1. Click **"Databases"** in left menu
2. Select **"chronicle"** database
3. Click **"Tables"** tab
4. Click **"public.events"** table
5. View your events!

### SQL Queries (via CLI)
```bash
# Connect to CockroachDB
docker exec -it chronicle-cockroach ./cockroach sql --insecure

# Switch to database
USE chronicle;

# See all events
SELECT event_id, aggregate_id, event_type, created_at 
FROM events 
ORDER BY created_at DESC 
LIMIT 10;

# See events for specific account
SELECT event_type, event_data, created_at 
FROM events 
WHERE aggregate_id = 'ACC-TEST-001' 
ORDER BY created_at DESC;

# Count total events
SELECT COUNT(*) FROM events;
```

**What You'll See:**
- ✅ `AccountCreated` events
- ✅ `MoneyDeposited` events
- ✅ `MoneyWithdrawn` events
- ✅ Full event history (immutable audit log)

---

## 2️⃣ PostgreSQL - Read Model

### DBeaver (Recommended for GUI)

**Connection Details:**
- Host: `localhost`
- Port: `5433`
- Database: `chronicle`
- Username: `chronicle`
- Password: `chronicle`

**Tables to Check:**

#### A. `account_balance` - Current Account State
```sql
-- See all accounts
SELECT account_id, owner_name, balance, currency, status, created_at
FROM account_balance
ORDER BY created_at DESC;

-- Check specific account
SELECT * FROM account_balance WHERE account_id = 'ACC-TEST-001';
```

**Expected Output:**
```
| account_id   | owner_name  | balance  | currency |
| ------------ | ----------- | -------- | -------- |
| ACC-TEST-001 | Harsha Test | 15000.00 | USD      |
| ACC-001      | Harsha A.   | 5000.00  | USD      |
```

#### B. `transactions` - Transaction History
```sql
-- Recent transactions
SELECT transaction_id, account_id, amount, balance_after, description, created_at
FROM transactions
ORDER BY created_at DESC
LIMIT 10;
```

#### C. `transfers` - Transfer Details
```sql
-- See all transfers
SELECT transfer_id, from_account_id, to_account_id, amount, status, created_at
FROM transfers
ORDER BY created_at DESC;
```

#### D. `events` - Empty (Not Used)
```sql
-- This will return 0
SELECT COUNT(*) FROM events;
```
⚠️ **Note:** This table exists but is NOT used. Events are stored in CockroachDB!

### PostgreSQL CLI
```bash
# Connect via Docker
docker exec -it chronicle-db psql -U chronicle -d chronicle

# List all tables
\dt

# Query account balances
SELECT * FROM account_balance;

# Exit
\q
```

---

## 3️⃣ Dashboard UI (Browser)

**URL:** http://localhost:3000

**Features:**
- 📊 Real-time event stream
- 🔄 Auto-refreshes every 2 seconds
- 🔍 Filter events by type
- 📋 Copy event details to clipboard
- 🎨 JSON syntax highlighting

**What You'll See:**
- All events from CockroachDB in chronological order
- Event type badges (AccountCreated, MoneyDeposited, etc.)
- Expandable event details
- Aggregate ID (account ID) for each event

---

## 4️⃣ API Endpoints (Testing via curl/Postman)

### Query API (Port 4001)

```powershell
# Get account details
curl http://localhost:4001/accounts/ACC-TEST-001

# Get account balance at specific time (Time-Travel!)
$timestamp = "2026-01-05T05:28:00Z"
curl "http://localhost:4001/accounts/ACC-TEST-001/balance-at?timestamp=$timestamp"

# Get all events
curl http://localhost:4001/events?limit=20

# Get events for specific account
curl http://localhost:4001/events?aggregate_id=ACC-TEST-001
```

### Ledger API (Port 4002)

```powershell
# Health check
curl http://localhost:4002/health

# Create account
Invoke-RestMethod -Method POST -Uri 'http://localhost:4002/commands/create-account' `
  -Headers @{'Content-Type'='application/json'} `
  -Body '{"account_id":"ACC-NEW","owner_name":"New User","initial_balance":1000,"currency":"USD"}'

# Deposit money
Invoke-RestMethod -Method POST -Uri 'http://localhost:4002/commands/deposit' `
  -Headers @{'Content-Type'='application/json'} `
  -Body '{"account_id":"ACC-TEST-001","amount":500,"description":"Test deposit"}'
```

---

## 5️⃣ Quick Verification Scripts

Located in `scripts/` folder:

### Show All Data
```powershell
.\scripts\show-all-data.ps1
```
Shows:
- All events in CockroachDB
- All accounts in PostgreSQL
- Summary

### Test Create Account
```powershell
.\scripts\test-create-account.ps1
```
Creates account and verifies data flow

### Test Deposit Flow
```powershell
.\scripts\test-deposit-flow.ps1
```
Tests deposit and checks both databases

---

## 🎯 What to Check for Each Operation

### After Creating Account:
1. ✅ CockroachDB `events` → New `AccountCreated` event
2. ✅ PostgreSQL `account_balance` → New row with initial balance
3. ✅ Dashboard → Event appears in stream

### After Deposit:
1. ✅ CockroachDB `events` → New `MoneyDeposited` event
2. ✅ PostgreSQL `account_balance` → Balance INCREASED
3. ✅ PostgreSQL `transactions` → New transaction record

### After Transfer:
1. ✅ CockroachDB `events` → Two events (Withdrawn + Deposited)
2. ✅ PostgreSQL `account_balance` → Both balances updated
3. ✅ PostgreSQL `transfers` → New transfer record

---

## 🔍 Troubleshooting

### "I don't see any data!"

**Check CockroachDB:**
```bash
docker exec -it chronicle-cockroach ./cockroach sql --insecure -e "SELECT COUNT(*) FROM chronicle.events;"
```
If count = 0, no events have been created yet!

**Check PostgreSQL:**
```bash
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT COUNT(*) FROM account_balance;"
```

**Check Services:**
```powershell
# Are APIs running?
curl http://localhost:4002/health  # Ledger API
curl http://localhost:4001/health  # Query API
```

### "Events in CockroachDB but not in PostgreSQL read model!"

Check if Read Processor is running:
```powershell
Get-Process node
```
Should see multiple node processes.

Check NATS connection:
```powershell
curl http://localhost:8222/connz
```

---

## 📝 Summary

| What                    | Where                          | How                          |
| ----------------------- | ------------------------------ | ---------------------------- |
| **Event Log**           | CockroachDB → `events`         | http://localhost:8080 or SQL |
| **Account Balances**    | PostgreSQL → `account_balance` | DBeaver or SQL               |
| **Transactions**        | PostgreSQL → `transactions`    | DBeaver or SQL               |
| **Visual Event Stream** | Dashboard UI                   | http://localhost:3000        |
| **API Testing**         | Ledger/Query APIs              | curl/Postman                 |

**Remember:** 
- 📝 Events = CockroachDB (Write path)
- 📊 Read Model = PostgreSQL (Read path)
- 🎨 Visualization = Dashboard UI

---

**All data is there - just in different places by design (CQRS pattern)!**
