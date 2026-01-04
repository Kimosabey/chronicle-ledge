# 🧪 ChronicleLedger - Interactive Testing Guide

> **IMPORTANT**: All services are already running in another terminal!
> Open a NEW PowerShell window and run these commands one by one.

---

## ✅ Step 1: Verify Services are Running

```powershell
# Check if all services respond
curl http://localhost:4000/health
# Expected: {"status":"ok","service":"ledger-api"}

curl http://localhost:4001/health
# Expected: {"status":"ok","service":"query-api"}
```

---

## 🏦 Step 2: Create Your First Account

```powershell
curl -X POST http://localhost:4000/commands/create-account `
  -H "Content-Type: application/json" `
  -d '{
    "account_id": "ACC-001",
    "owner_name": "Harshan Aiyappa",
    "initial_balance": 5000,
    "currency": "USD"
  }'
```

**Expected Response**:
```json
{"success":true,"event_id":"<some-uuid>"}
```

**What just happened?**
1. ✅ Ledger API validated your command
2. ✅ Created `AccountCreated` event
3. ✅ Saved to PostgreSQL events table
4. ✅ Published to NATS (`events.account.created`)
5. ✅ Read Processor consumed event
6. ✅ Updated account_balance table

---

## 🔍 Step 3: Query the Account

```powershell
curl http://localhost:4001/accounts/ACC-001
```

**Expected Response**:
```json
{
  "account_id": "ACC-001",
  "owner_name": "Harshan Aiyappa",
  "balance": "5000.00",
  "currency": "USD",
  "created_at": "2026-01-04T..."
}
```

**Why this is cool**: The data came from the READ MODEL (optimized for queries), not the event store!

---

## 💰 Step 4: Deposit Money

```powershell
curl -X POST http://localhost:4000/commands/deposit `
  -H "Content-Type: application/json" `
  -d '{
    "account_id": "ACC-001",
    "amount": 2500,
    "description": "January Salary"
  }'
```

**Now check balance again**:
```powershell
curl http://localhost:4001/accounts/ACC-001
# Should show 7500.00 now!
```

---

## 🏦 Step 5: Create Second Account for Transfer

```powershell
curl -X POST http://localhost:4000/commands/create-account `
  -H "Content-Type: application/json" `
  -d '{
    "account_id": "ACC-002",
    "owner_name": "Alice Johnson",
    "initial_balance": 1000,
    "currency": "USD"
  }'
```

---

## 💸 Step 6: Transfer Money Between Accounts

```powershell
curl -X POST http://localhost:4000/commands/transfer `
  -H "Content-Type: application/json" `
  -d '{
    "from_account_id": "ACC-001",
    "to_account_id": "ACC-002",
    "amount": 1500,
    "description": "Payment for consulting services"
  }'
```

**Check both balances**:
```powershell
curl http://localhost:4001/accounts/ACC-001  # Should be 6000
curl http://localhost:4001/accounts/ACC-002  # Should be 2500
```

**What happened?**
- Created 2 events: `MoneyWithdrawn` (ACC-001) + `MoneyDeposited` (ACC-002)
- Both linked by same `transfer_id`
- Both account balances updated atomically

---

## ⏰ Step 7: TIME-TRAVEL QUERY (The Star Feature!)

**Save current timestamp BEFORE making a change**:
```powershell
$beforeTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Write-Host "Saved timestamp: $beforeTimestamp"
```

**Make another deposit**:
```powershell
curl -X POST http://localhost:4000/commands/deposit `
  -H "Content-Type: application/json" `
  -d '{
    "account_id": "ACC-001",
    "amount": 500,
    "description": "Bonus payment"
  }'
```

**Check CURRENT balance**:
```powershell
curl http://localhost:4001/accounts/ACC-001
# Should show 6500
```

**Now query PAST balance (before the bonus!)**:
```powershell
curl "http://localhost:4001/accounts/ACC-001/balance-at?timestamp=$beforeTimestamp"
# Should show 6000 - the balance BEFORE the deposit!
```

**🤯 Mind-blowing!** You just queried historical state without any snapshots!

---

## 📜 Step 8: View Complete Event Log

```powershell
curl http://localhost:4001/events?limit=20
```

**You'll see ALL events in chronological order**:
- AccountCreated
- MoneyDeposited
- MoneyWithdrawn  
- MoneyDeposited (transfer)
- etc.

**This is your audit trail!** Every state change is recorded forever.

---

## 🎨 Step 9: Open the Dashboard

**In your browser, go to**:
```
http://localhost:3000
```

**What you'll see**:
- ✅ Real-time event stream (auto-refreshes every 2 seconds)
- ✅ Filter events by type
- ✅ Expandable JSON details
- ✅ Copy-to-clipboard buttons

---

## 🧪 Step 10: Run Automated Tests

```powershell
cd "g:\LearningRelated\Portfolio Project\chronicle-ledge"
node scripts/e2e-test.js
```

**This will automatically test**:
1. Create account
2. Deposit
3. Transfer
4. Withdrawal
5. Time-travel query
6. Event log retrieval

---

## 🔍 Step 11: Inspect the Database

**View event store (raw events)**:
```powershell
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT event_id, aggregate_id, event_type, created_at FROM events ORDER BY created_at DESC LIMIT 10;"
```

**View read model (materialized views)**:
```powershell
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT * FROM account_balance;"
```

---

## 📊 Understanding What You Built

### **The Flow**

```
USER COMMAND (via curl)
    ↓
LEDGER API (Validate + Create Event)
    ↓
PostgreSQL Event Store (Immutable append)
    ↓
NATS Message Bus (Publish event)
    ↓
READ PROCESSOR (NATS Consumer)
    ↓
PostgreSQL Read Model (Update materialized view)
    ↓
QUERY API (Fast reads from read model)
```

### **CQRS Pattern**

**Command Side (Writes)**:
- Ledger API → Event Store
- Validates business rules
- Creates immutable events
- Publishes to NATS

**Query Side (Reads)**:
- Query API → Read Model
- Optimized for fast lookups
- Materialized views
- Time-travel via event replay

---

## 🎯 Key Concepts to Explain in Interviews

### 1. **Event Sourcing**
> "Instead of storing current state, we store ALL events that led to that state. Current balance is computed by replaying events."

**Benefits**:
- Complete audit trail
- Time-travel debugging
- Never lose data
- Event replay for bug reproduction

### 2. **CQRS (Command Query Responsibility Segregation)**
> "Writes and reads use different data models. Writes append events, reads query materialized views."

**Benefits**:
- Independent scaling
- Optimized for each use case
- Clear separation of concerns

### 3. **Time-Travel Queries**
> "By replaying events up to a specific timestamp, we can reconstruct state at any point in history."

**Use Cases**:
- Debugging: "Why did this account go negative last week?"
- Compliance: "Show account state at time of audit"
- Analytics: "Historical balance trends"

### 4. **Eventual Consistency**
> "The read model updates asynchronously via NATS. There's a small delay (~ms) between write and read visibility."

**Tradeoff**:
- ✅ Better scalability
- ✅ Loose coupling
- ⚠️ Need to handle eventual consistency in UX

---

## 🐛 Troubleshooting

### Services not responding?
```powershell
# Check if they're running
Get-NetTCPConnection -LocalPort 4000,4001,3000
```

### Database connection issues?
```powershell
docker ps  # Check if chronicle-db is healthy
docker logs chronicle-db  # View logs
```

### Events not appearing in read model?
```powershell
# Check NATS connection
curl http://localhost:8222/connz
```

---

## 🎓 What to Show Recruiters

1. **Architecture diagram** (`docs/HLD.md`)
2. **Live demo**:
   - Create account
   - Transfer money
   - Time-travel query ← THIS IS THE WOW MOMENT
3. **Code walkthrough**:
   - Event creation (`services/ledger-api/src/index.ts`)
   - Event replay for time-travel (`services/query-api/src/index.ts:51-88`)
4. **Documentation depth** (HLD, LLD, Interview guide)

---

## 📝 Next Steps

1. ✅ Run all these commands
2. ✅ Take screenshots
3. ✅ Record a 2-minute demo video
4. ✅ Read `LINEARIZABILITY.md` to understand consistency guarantees
5. ✅ Practice explaining Event Sourcing + CQRS

---

**You now have a COMPLETE Event Sourcing system running!** 🎉

**Commands to remember**:
- Create: `POST /commands/create-account`
- Deposit: `POST /commands/deposit`
- Transfer: `POST /commands/transfer`
- Query: `GET /accounts/:id`
- Time-travel: `GET /accounts/:id/balance-at?timestamp=X`
- Events: `GET /events`

**Everything is working! Start testing!** 🚀
