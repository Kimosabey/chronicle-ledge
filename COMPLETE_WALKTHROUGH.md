# 🎓 ChronicleLedger - Complete Project Walkthrough

> **Your Personal Guide**: Everything you need to understand, run, and showcase this project

---

## 📚 Table of Contents

1. [Project Overview - What Did You Build?](#1-project-overview)
2. [Architecture Deep Dive - How Does It Work?](#2-architecture-deep-dive)
3. [Step-by-Step Startup Guide](#3-step-by-step-startup)
4. [Testing Every Feature](#4-testing-every-feature)
5. [What to Show Recruiters](#5-what-to-show-recruiters)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. Project Overview - What Did You Build?

### 🎯 **The Big Picture**

You built a **production-grade Event Sourcing system** - a banking ledger that:
- Never deletes data (append-only event log)
- Can query account balance at ANY point in history (time-travel!)
- Separates writes from reads (CQRS pattern)
- Uses modern distributed systems patterns

### 💡 **Why This Matters to Recruiters**

This project proves you understand:
- ✅ **Advanced Architecture Patterns** (Event Sourcing + CQRS)
- ✅ **Distributed Systems** (eventual consistency, event-driven design)
- ✅ **Modern Full-Stack** (TypeScript, Node.js, Next.js)
- ✅ **System Design** (scalability, fault tolerance, audit compliance)

### 🏗️ **Tech Stack**

| Layer | Technology | Purpose |
|:------|:-----------|:--------|
| **Event Store** | PostgreSQL | Immutable log of all events |
| **Read Database** | PostgreSQL | Fast queries (materialized views) |
| **Message Bus** | NATS | Pub/sub for event distribution |
| **Write API** | Node.js + Fastify | Handle commands (deposits, transfers) |
| **Query API** | Node.js + Fastify | Fast reads + time-travel queries |
| **Event Processor** | Node.js | Consumes events, updates read model |
| **Dashboard** | Next.js 14 | Real-time event viewer UI |

---

## 2. Architecture Deep Dive - How Does It Work?

### 🔄 **The Event Sourcing Flow**

```
USER ACTION (Deposit $100)
    ↓
LEDGER API (Validate, Create Event)
    ↓
SAVE EVENT to PostgreSQL Event Store
    ↓
PUBLISH EVENT to NATS Message Bus
    ↓
READ PROCESSOR (NATS Consumer)
    ↓
UPDATE READ MODEL (PostgreSQL Materialized Views)
    ↓
QUERY API (Fast lookups from Read Model)
```

### 🎯 **CQRS Pattern Explained**

**CQRS** = Command Query Responsibility Segregation

**Commands (Writes)** → Ledger API → Event Store
- POST /commands/create-account
- POST /commands/deposit
- POST /commands/withdraw
- POST /commands/transfer

**Queries (Reads)** → Query API → Read Model
- GET /accounts/:id
- GET /accounts/:id/balance-at?timestamp=X  ← **TIME TRAVEL!**
- GET /accounts/:id/transactions
- GET /events

### ⏰ **Time-Travel Queries - The Star Feature**

**How it works**:
1. User asks: "What was account ACC-001's balance on Jan 1, 2026 at 10 AM?"
2. Query API fetches ALL events for ACC-001 **before** that timestamp
3. Replays events in order: Created → Deposited → Withdrawn → Deposited
4. Returns the calculated balance at that exact moment

**Why it's powerful**:
- Debug issues: "Why did this account have negative balance last week?"
- Compliance: "Prove account state at time of audit"
- Analytics: "Show balance trends over time"

---

## 3. Step-by-Step Startup

### ✅ **Phase 1: Infrastructure (Already Running!)**

Check if Docker containers are running:
```powershell
docker ps
```

**What you should see**:
```
chronicle-db (PostgreSQL)   - Port 5433 - Healthy ✓
chronicle-nats (NATS)       - Ports 4222/8222 - Healthy ✓
```

**What these do**:
- `chronicle-db`: Stores BOTH event log AND read model (simplified setup)
- `chronicle-nats`: Message bus for event distribution

---

### ✅ **Phase 2: Install Dependencies**

```powershell
cd "g:\LearningRelated\Portfolio Project\chronicle-ledge"
npm install
```

**What this installs**:
- Root dependencies: `concurrently`, `pg`, `node-fetch`
- Ledger API: `fastify`, `@fastify/cors`, `uuid`, `nats`
- Query API: Same as Ledger API
- Read Processor: NATS client, PostgreSQL client
- Dashboard: Next.js, React, TypeScript

**Wait time**: ~2-3 minutes

---

### ✅ **Phase 3: Initialize Database Schema**

The database schema is already created via the init script in docker-compose!

**Verify it worked**:
```powershell
# Check if tables exist
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "\dt"
```

**What you should see**:
- `events` table (event store)
- `account_balance` table (read model)
- `transactions` table (read model)

---

### ✅ **Phase 4: Start All Services**

```powershell
npm run dev
```

**What this starts** (all at once):
1. **Ledger API** - Port 4000 - Handles write commands
2. **Read Processor** - No port (NATS consumer) - Updates read model
3. **Query API** - Port 4001 - Handles read queries
4. **Dashboard** - Port 3000 - Web UI

**What you should see in terminal**:
```
[ledger-api] Server listening on http://0.0.0.0:4000
[ledger-api] Connected to PostgreSQL (Event Store)
[ledger-api] Connected to NATS
[query-api] Server listening on http://0.0.0.0:4001
[query-api] Connected to PostgreSQL (Read Model)
[read-processor] Connected to NATS
[read-processor] Subscribed to events.account.*
[dashboard] ready started server on 0.0.0.0:3000
```

---

## 4. Testing Every Feature

### 🧪 **Test 1: Health Checks**

**What**: Verify all services are reachable
**Why**: Confirm infrastructure is working

```powershell
# Test Ledger API
curl http://localhost:4000/health

# Test Query API
curl http://localhost:4001/health
```

**Expected Response**:
```json
{"status":"ok","service":"ledger-api"}
{"status":"ok","service":"query-api"}
```

---

### 🧪 **Test 2: Create an Account**

**What**: Create your first account
**Why**: This writes the first event to the system

```powershell
curl -X POST http://localhost:4000/commands/create-account `
  -H "Content-Type: application/json" `
  -d '{
    "account_id": "ACC-001",
    "owner_name": "Alice Johnson",
    "initial_balance": 1000,
    "currency": "USD"
  }'
```

**Expected Response**:
```json
{"success":true,"event_id":"<uuid>"}
```

**What just happened**:
1. ✅ Ledger API validated the command
2. ✅ Created `AccountCreated` event
3. ✅ Saved event to PostgreSQL `events` table
4. ✅ Published event to NATS topic `events.account.created`
5. ✅ Read Processor consumed event
6. ✅ Updated `account_balance` table with balance=1000

**Verify it worked**:
```powershell
# Query the account
curl http://localhost:4001/accounts/ACC-001
```

**Expected**:
```json
{
  "account_id": "ACC-001",
  "owner_name": "Alice Johnson",
  "balance": "1000.00",
  "currency": "USD"
}
```

---

### 🧪 **Test 3: Deposit Money**

**What**: Add $500 to account
**Why**: Test event append and read model update

```powershell
curl -X POST http://localhost:4000/commands/deposit `
  -H "Content-Type: application/json" `
  -d '{
    "account_id": "ACC-001",
    "amount": 500,
    "description": "Salary payment"
  }'
```

**What happens**:
- Event: `MoneyDeposited` with amount=500
- Read Model: `balance` updates from 1000 → 1500

**Verify**:
```powershell
curl http://localhost:4001/accounts/ACC-001
# Should show balance: 1500.00
```

---

### 🧪 **Test 4: Transfer Between Accounts**

**What**: Create second account, transfer money
**Why**: Tests atomic multi-event transactions

```powershell
# Create second account
curl -X POST http://localhost:4000/commands/create-account `
  -H "Content-Type: application/json" `
  -d '{
    "account_id": "ACC-002",
    "owner_name": "Bob Smith",
    "initial_balance": 500,
    "currency": "USD"
  }'

# Transfer $200 from Alice to Bob
curl -X POST http://localhost:4000/commands/transfer `
  -H "Content-Type: application/json" `
  -d '{
    "from_account_id": "ACC-001",
    "to_account_id": "ACC-002",
    "amount": 200,
    "description": "Payment for services"
  }'
```

**What happens**:
- 2 events created: `MoneyWithdrawn` (ACC-001) + `MoneyDeposited` (ACC-002)
- Both events have same `transfer_id` for linking
- Read Model updates BOTH balances

**Verify**:
```powershell
curl http://localhost:4001/accounts/ACC-001  # Should be 1300
curl http://localhost:4001/accounts/ACC-002  # Should be 700
```

---

### 🧪 **Test 5: Time-Travel Query** ⭐

**What**: Query historical balance
**Why**: This is the COOLEST feature - shows Event Sourcing power!

```powershell
# First, note the current time
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Do another deposit
curl -X POST http://localhost:4000/commands/deposit `
  -H "Content-Type: application/json" `
  -d '{"account_id":"ACC-001","amount":100,"description":"Bonus"}'

# Current balance
curl http://localhost:4001/accounts/ACC-001
# Should show 1400

# Balance BEFORE the last deposit (use the timestamp from above)
curl "http://localhost:4001/accounts/ACC-001/balance-at?timestamp=$timestamp"
# Should show 1300 (the balance BEFORE the deposit!)
```

**Why this is impressive**:
- No snapshots needed!
- Query ANY point in history
- Perfect audit trail
- Compliance-ready

---

### 🧪 **Test 6: View Event Log**

**What**: See ALL events in the system
**Why**: Complete audit trail

```powershell
curl http://localhost:4001/events?limit=50
```

**What you'll see**:
```json
{
  "events": [
    {
      "event_id": "...",
      "aggregate_id": "ACC-001",
      "event_type": "MoneyDeposited",
      "event_data": {"amount": 100, "description": "Bonus"},
      "created_at": "2026-01-04T15:15:30Z"
    },
    {
      "event_type": "MoneyDeposited",
      "event_data": {"amount": 200, "transfer_id": "..."}
    },
    ...
  ]
}
```

---

### 🧪 **Test 7: Dashboard UI**

**What**: Visual interface
**Why**: Easier to explore than curl commands

**Open in browser**:
```
http://localhost:3000
```

**What you'll see**:
- Real-time event stream (auto-refreshes every 2 seconds)
- Filter events by type
- Expandable JSON details
- Copy-to-clipboard functionality

---

### 🧪 **Test 8: Automated E2E Test**

**What**: Run the full test suite
**Why**: Tests all features at once

```powershell
node scripts/e2e-test.js
```

**What it tests**:
1. ✅ Create account
2. ✅ Deposit money
3. ✅ Transfer between accounts
4. ✅ Withdraw money
5. ✅ Time-travel query
6. ✅ Event log retrieval

**Expected output**:
```
✅ Account created successfully
✅ Deposit successful
✅ Transfer successful
✅ Withdrawal successful
✅ Time-travel query successful
✅ All tests passed!
```

---

## 5. What to Show Recruiters

### 📸 **Demo Flow for Interviews**

**1. Start with the "Why"** (30 seconds)
> "This project demonstrates Event Sourcing and CQRS - patterns used by companies like Uber and Netflix for systems that need complete audit trails and time-travel debugging."

**2. Show the Architecture Diagram** (1 minute)
- Open `docs/HLD.md`
- Explain: Write path (commands) vs Read path (queries)
- Highlight: NATS for async event distribution

**3. Live Demo** (3 minutes)
```powershell
# Show services running
docker ps
Get-Process | Where-Object {$_.ProcessName -like "*node*"}

# Create account and show immediate query
curl -X POST http://localhost:4000/commands/create-account ...
curl http://localhost:4001/accounts/ACC-001

# Time-travel demo
curl "http://localhost:4001/accounts/ACC-001/balance-at?timestamp=..."
```

**4. Show the Code** (2 minutes)
- **Event Creation**: `services/ledger-api/src/index.ts` (lines 25-66)
- **Event Replay**: `services/query-api/src/index.ts` (lines 51-88)
- **Event Processing**: `services/read-processor/src/index.ts`

**5. Explain Trade-offs** (1 minute)
> "Event Sourcing gives us complete audit history and time-travel, but adds complexity - we need to maintain two data models and handle eventual consistency. I chose this pattern because audit compliance was a key requirement."

---

### 💬 **Key Talking Points**

✅ **Event Sourcing**: "Instead of UPDATE statements, we only INSERT events. The current state is derived by replaying all events."

✅ **CQRS**: "Writes go to one optimized path (event store), reads go to another (materialized views). This separates concerns and scales independently."

✅ **Time-Travel**: "By replaying events up to a specific timestamp, we can query historical state without storing snapshots."

✅ **Distributed Systems**: "Originally designed for CockroachDB (distributed database), simplified to PostgreSQL but the patterns remain the same."

✅ **Production Ready**: "Includes health checks, error handling, idempotency design, and comprehensive documentation."

---

## 6. Troubleshooting

### ❌ **Problem**: Services won't start - "concurrently: command not found"
**Solution**:
```powershell
npm install
# Wait for installation to complete, then:
npm run dev
```

---

### ❌ **Problem**: Docker containers not running
**Solution**:
```powershell
docker-compose up -d
# Wait 10 seconds for health checks
docker ps
```

---

### ❌ **Problem**: "Cannot connect to PostgreSQL"
**Solution**:
```powershell
# Check if container is healthy
docker ps
# If unhealthy, restart
docker-compose restart postgres
# Wait 10 seconds
docker exec -it chronicle-db pg_isready -U chronicle
```

---

### ❌ **Problem**: Transfer fails with "Insufficient funds"
**Solution**: This is CORRECT behavior! Event Sourcing validates business rules. Check current balance first:
```powershell
curl http://localhost:4001/accounts/ACC-001
```

---

### ❌ **Problem**: Read Model is out of sync with Event Store
**Solution**: Run consistency check:
```powershell
node scripts/verify-consistency.js
```

---

## 🎓 **Understanding Your Code**

### 📂 **Project Structure**

```
chronicle-ledge/
├── docker-compose.yml          ← Infrastructure definition
├── package.json                ← Workspace root
├── services/
│   ├── ledger-api/            ← Write service (commands)
│   │   └── src/
│   │       ├── index.ts       ← Main API (326 lines)
│   │       ├── db.ts          ← PostgreSQL connection
│   │       └── nats.ts        ← NATS publisher
│   ├── query-api/             ← Read service (queries)
│   │   └── src/
│   │       ├── index.ts       ← Query endpoints + time-travel
│   │       ├── db.ts          ← Read model connection
│   │       └── eventStore.ts  ← Event store connection
│   └── read-processor/        ← Event consumer
│       └── src/
│           └── index.ts       ← NATS subscriber + view updater
├── ui/
│   └── dashboard/             ← Next.js UI
│       └── src/
│           └── app/
│               └── page.tsx   ← Event log viewer
├── scripts/
│   ├── e2e-test.js           ← Automated test suite
│   ├── simulate-traffic.js   ← Load generator
│   └── verify-consistency.js ← Data validation
└── docs/
    ├── HLD.md                 ← Architecture diagrams
    ├── LLD.md                 ← API contracts
    ├── EVENT_SOURCING.md      ← Pattern explanation
    ├── FAILURE_SCENARIOS.md   ← Chaos testing
    └── INTERVIEW.md           ← Q&A prep (30+ questions)
```

---

### 🔑 **Key Code Sections**

#### **1. Event Creation (Ledger API)**
**File**: `services/ledger-api/src/index.ts:33-66`

```typescript
// Validate command
if (!account_id || !owner_name) {
  return reply.status(400).send({ error: 'Missing fields' });
}

// Create event object
const event = {
  event_id: uuidv4(),
  aggregate_id: account_id,
  event_type: 'AccountCreated',
  event_data: { owner_name, initial_balance, currency },
  created_at: new Date().toISOString()
};

// Persist to event store
await query('INSERT INTO events (...) VALUES (...)', [...]);

// Publish to NATS
await publishEvent('events.account.created', event);
```

**Why this matters**: Demonstrates event-driven write path with persistence + messaging.

---

#### **2. Time-Travel Query (Query API)**
**File**: `services/query-api/src/index.ts:51-88`

```typescript
// Fetch all events BEFORE the timestamp
const res = await queryEvents(
  'SELECT event_type, event_data FROM events WHERE aggregate_id = $1 AND created_at <= $2 ORDER BY created_at ASC',
  [id, timestamp]
);

let balance = 0;
// Replay events in order
for (const row of res.rows) {
  if (row.event_type.includes('Created')) {
    balance = parseFloat(data.initial_balance);
  } else if (row.event_type.includes('Deposited')) {
    balance += parseFloat(data.amount);
  } else if (row.event_type.includes('Withdrawn')) {
    balance -= parseFloat(data.amount);
  }
}

return { account_id: id, balance, at: timestamp };
```

**Why this matters**: Shows event replay for state reconstruction - the CORE of Event Sourcing.

---

#### **3. Event Consumer (Read Processor)**
**File**: `services/read-processor/src/index.ts`

```typescript
// Subscribe to all account events
await nc.subscribe('events.account.*', {
  async callback(err, msg) {
    const event = JSON.parse(msg.data);
    
    // Update read model based on event type
    if (event.event_type === 'AccountCreated') {
      await query('INSERT INTO account_balance ...');
    } else if (event.event_type === 'MoneyDeposited') {
      await query('UPDATE account_balance SET balance = balance + $1 ...');
    }
  }
});
```

**Why this matters**: Demonstrates eventual consistency and materialized view pattern.

---

## 🎯 **Learning Outcomes**

After completing this walkthrough, you now understand:

✅ **Event Sourcing**: Append-only log, state from events  
✅ **CQRS**: Separate read/write models  
✅ **Time-Travel**: Event replay for historical queries  
✅ **Event-Driven Architecture**: NATS pub/sub  
✅ **Distributed Patterns**: Eventual consistency  
✅ **Modern Full-Stack**: TypeScript, Node.js, Next.js  
✅ **Docker Orchestration**: Multi-container setup  
✅ **System Design**: Scalability, fault tolerance, audit compliance  

---

## 🚀 **Next Steps**

1. **Run the project** using this guide
2. **Take screenshots** of:
   - Architecture diagram from docs/HLD.md
   - Terminal showing all services running
   - Dashboard UI at localhost:3000
   - Time-travel query result
3. **Record a demo video** (2-3 minutes)
4. **Update your resume** with:
   - "Built event-sourced banking system with time-travel queries"
   - "Implemented CQRS pattern with Node.js and PostgreSQL"
   - "Designed distributed architecture with NATS messaging"

---

## 📞 **Questions for Interviews**

Be ready to answer:

1. **"Why Event Sourcing over traditional CRUD?"**
   > "Event Sourcing provides a complete audit trail, time-travel debugging, and makes it impossible to lose data since we never delete. The tradeoff is increased complexity in maintaining two data models."

2. **"How do you handle eventual consistency?"**
   > "The read model updates asynchronously via NATS events. In production, I would add idempotency keys and retry logic. For critical reads, I'd allow clients to query the event store directly for strong consistency."

3. **"How does this scale?"**
   > "The write path (Ledger API) scales horizontally - each instance writes to the same event store. The read path scales independently - we can add read replicas. NATS handles event distribution across multiple consumers."

---

**Built with**: Event Sourcing • CQRS • PostgreSQL • NATS • Next.js  
**Author**: Harshan Aiyappa  
**Purpose**: Portfolio project demonstrating senior-level distributed systems knowledge
