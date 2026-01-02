# Chronicle Ledger - Complete Setup Guide

![Setup Guide](./docs/images/setup-guide.png)

## 🚀 Quick Start (5 Minutes)

### Prerequisites
- **Docker & Docker Compose** (for databases & NATS)
- **Node.js 18+** (for services & UI)
- **Git** (to clone the repo)

### Step 1: Start Infrastructure
```bash
docker-compose up -d
```

This starts:
- **CockroachDB** (port 26257) - Event Store
- **PostgreSQL** (port 5433) - Read Model
- **NATS** (port 4222) - Message Bus

### Step 2: Initialize CockroachDB
The Postgres init script runs automatically, but CockroachDB needs manual initialization:

```bash
# Windows PowerShell
Get-Content infra/cockroach/init.sql | docker exec -i chronicle-cockroach ./cockroach sql --insecure

# Linux/Mac
cat infra/cockroach/init.sql | docker exec -i chronicle-cockroach ./cockroach sql --insecure
```

### Step 3: Start All Services
```bash
npm install
npm run dev
```

This starts:
- **Ledger API** (port 4002) - Command endpoint
- **Query API** (port 4001) - Query endpoint
- **Read Processor** - Event consumer
- **Dashboard** (port 3000) - Web UI

### Step 4: Open the Dashboard
Navigate to: `http://localhost:3000`

---

## 🧪 Testing & Verification

### Run End-to-End Test
```bash
node scripts/e2e-test.js
```

This tests:
1. Account creation
2. Deposit funds
3. Transfer between accounts
4. Withdraw funds
5. Balance verification
6. **Time-travel queries** (get balance at past timestamp)
7. Audit log verification

### Verify System Consistency
```bash
node scripts/verify-consistency.js
```

Compares event count in CockroachDB vs transaction count in PostgreSQL.

### Simulate Traffic (Chaos Testing)
```bash
# Continuous traffic
node scripts/simulate-traffic.js --continuous

# Run 100 transactions and stop
node scripts/simulate-traffic.js
```

---

## 📚 API Reference

### Ledger API (Write Commands) - Port 4002

#### Create Account
```http
POST http://localhost:4002/commands/create-account
Content-Type: application/json

{
  "account_id": "ACC-001",
  "owner_name": "Alice",
  "initial_balance": 1000.00,
  "currency": "USD"
}
```

#### Deposit Money
```http
POST http://localhost:4002/commands/deposit
Content-Type: application/json

{
  "account_id": "ACC-001",
  "amount": 500.00,
  "description": "Salary"
}
```

#### Withdraw Money
```http
POST http://localhost:4002/commands/withdraw
Content-Type: application/json

{
  "account_id": "ACC-001",
  "amount": 100.00,
  "description": "Cash withdrawal"
}
```

#### Transfer Between Accounts
```http
POST http://localhost:4002/commands/transfer
Content-Type: application/json

{
  "from_account_id": "ACC-001",
  "to_account_id": "ACC-002",
  "amount": 200.00,
  "description": "Payment"
}
```

### Query API (Read Queries) - Port 4001

#### Get Account Balance
```http
GET http://localhost:4001/accounts/ACC-001
```

Response:
```json
{
  "account_id": "ACC-001",
  "owner_name": "Alice",
  "balance": "1200.00",
  "currency": "USD",
  "status": "active"
}
```

#### Get Transaction History
```http
GET http://localhost:4001/accounts/ACC-001/transactions
```

#### Get Balance at Specific Time (Time-Travel!)
```http
GET http://localhost:4001/accounts/ACC-001/balance-at?timestamp=2026-01-02T10:00:00Z
```

Response:
```json
{
  "account_id": "ACC-001",
  "balance": "800.00",
  "currency": "USD",
  "at": "2026-01-02T10:00:00Z"
}
```

#### Get Event Log
```http
GET http://localhost:4001/events?limit=100
```

---

## 🗂️ Project Structure

```
chronicle-ledge/
├── services/
│   ├── ledger-api/          # Write side (Commands)
│   ├── query-api/           # Read side (Queries)
│   └── read-processor/      # Event consumer
├── ui/
│   └── dashboard/           # React/Next.js UI
├── infra/
│   ├── cockroach/           # CockroachDB init scripts
│   └── postgres-combined/   # PostgreSQL init scripts
├── scripts/
│   ├── e2e-test.js          # End-to-end verification
│   ├── verify-consistency.js # DB consistency check
│   └── simulate-traffic.js   # Load testing
└── docs/                    # Architecture docs
```

---

## 🔧 Troubleshooting

### "Database chronicle does not exist"
**Solution**: Run the CockroachDB init script (Step 2 above).

### "Address already in use"
**Solution**: Kill existing Node processes:
```bash
# Windows
Get-Process node | Stop-Process -Force

# Linux/Mac  
killall node
```

### Read Processor not updating PostgreSQL
**Solution**: Ensure NATS is running and services started in correct order.
```bash
docker-compose restart nats
npm run dev
```

### Wipe Everything and Start Fresh
```bash
docker-compose down -v  # Deletes all data
docker-compose up -d
# Then run Step 2 (init CockroachDB) again
npm run dev
```

---

## 🎯 What's Implemented

### ✅ Core Features
- **Event Sourcing**: All state changes stored as immutable events
- **CQRS**: Separate write (Ledger) and read (Query) models
- **Event-Driven**: NATS message broker for async processing
- **Time-Travel Queries**: Query balance at any point in history
- **Deposit/Withdraw**: Explicit endpoints for adding/removing funds
- **Transfers**: Move money between accounts atomically
- **Event Log Viewer**: Real-time UI to view all system events
- **Optimistic Concurrency**: Version-based conflict detection

### 🔮 Nice-to-Have (Optional)
- Idempotency key enforcement
- Account suspension/closure
- Multi-currency validation
- Rate limiting
- Authentication/Authorization
- Chaos testing demos
- Performance benchmarks

---

## 📊 Architecture Highlights

**Write Path (Commands)**:
```
UI → Ledger API → CockroachDB (events table) → NATS
```

**Read Path (Queries)**:
```
NATS → Read Processor → PostgreSQL → Query API → UI
```

**Time-Travel**:
```
Query API → CockroachDB (events WHERE created_at <= timestamp) → Replay events → Return balance
```

---

## 🎓 Learn More

- **Event Sourcing**: See `docs/EVENT_SOURCING.md`
- **High-Level Design**: See `docs/HLD.md`
- **Low-Level Design**: See `docs/LLD.md`
- **Failure Scenarios**: See `docs/FAILURE_SCENARIOS.md`
- **Interview Guide**: See `docs/INTERVIEW.md`

---

## 📝 Development Notes

### Database Connections

**CockroachDB (Event Store)**:
```
Host: localhost
Port: 26257
User: root
Database: chronicle
SSL: disabled (dev mode)
```

**PostgreSQL (Read Model)**:
```
Host: localhost
Port: 5433
User: chronicle
Password: chronicle
Database: chronicle
```

**NATS**:
```
URL: nats://localhost:4222
```

### Environment Variables

All services use `.env` files (copied from `.env.example`):
- `services/ledger-api/.env`
- `services/query-api/.env`
- `services/read-processor/.env`

---

## 🚨 Important Notes

1. **Account IDs**: Use string format (e.g., "ACC-001", "USER-123"). UUIDs not required.
2. **Amounts**: Always positive decimals (e.g., 100.50).
3. **Timestamps**: ISO 8601 format for time-travel queries.
4. **Docker Volumes**: Persist data across restarts. Use `docker-compose down -v` to wipe.

---

**Status**: ✅ Fully Operational  
**Last Updated**: January 2, 2026
