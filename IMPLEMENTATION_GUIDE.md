# ChronicleLedger - Implementation Guide

**Project**: Event-Sourced Ledger with CQRS  
**Started**: December 31, 2025

---

## Phase 1: Infrastructure ✅ (In Progress)

### Docker Services
- [ ] CockroachDB (Event Store) - starting...
- [ ] NATS JetStream (Message Bus) - starting...
- [ ] PostgreSQL (Read Model) - starting...

### Commands
```bash
# Start infrastructure
docker-compose -f docker-compose.dev.yml up -d

# Check status
docker-compose -f docker-compose.dev.yml ps

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Access CockroachDB
cockroach sql --insecure --host=localhost:26257

# Access PostgreSQL
psql -h localhost -p 5432 -U chronicle -d chronicle_read
```

---

## Phase 2: Core Services (Next)

### 1. Ledger API (Write Service)
**Location**: `services/ledger-api/`

**Tech Stack**:
- Node.js + TypeScript
- Express
- CockroachDB client
- NATS client

**API Endpoints**:
```
POST /api/accounts          - Create account
POST /api/accounts/:id/deposit  - Deposit money
POST /api/accounts/:id/withdraw - Withdraw money
POST /api/transfers         - Transfer money
```

**Key Features**:
- Event sourcing (append-only writes)
- Optimistic locking (version check)
- NATS event publishing
- Idempotency keys

---

### 2. Read Processor (Event Consumer)
**Location**: `services/read-processor/`

**Tech Stack**:
- Node.js + TypeScript
- NATS JetStream consumer
- PostgreSQL client

**Responsibilities**:
- Subscribe to NATS events
- Project events to PostgreSQL read models
- Update materialized views:
  - `account_balance`
  - `transactions`
  - `transfers`

---

### 3. Query API (Read Service)
**Location**: `services/query-api/`

**Tech Stack**:
- Node.js + TypeScript
- Express
- PostgreSQL client (read-only)

**API Endpoints**:
```
GET /api/accounts/:id           - Get account balance
GET /api/accounts/:id/transactions  - Get transaction history
GET /api/transactions/:id       - Get transaction details
GET /api/transfers/:id          - Get transfer details
```

---

### 4. Dashboard (UI)
**Location**: `ui/dashboard/`

**Tech Stack**:
- Next.js 14
- TypeScript
- Tailwind CSS
- Recharts (for visualizations)

**Pages**:
- Dashboard (metrics overview)
- Accounts list
- Account details
- Transaction history
- Transfer creation

---

## Phase 3: Testing & Demos

### Load Testing
```bash
npm run simulate            # Normal load
npm run simulate:continuous # Continuous traffic
```

### Chaos Testing
```bash
npm run chaos:kill-node     # Kill a CockroachDB node
npm run verify:cluster      # Verify cluster health
npm run verify:consistency  # Verify data consistency
```

### Visual Demos
1. **HA Demo**: Kill node, show writes continue
2. **Event Sourcing**: Show time-travel queries
3. **Consistency**: Show eventual consistency in read model

---

## Implementation Order

1. ✅ Documentation (HLD, LLD, etc.) - DONE
2. ✅ Docker Compose setup - DONE
3. 🔄 Start infrastructure - IN PROGRESS
4. ⏳ Implement Ledger API
5. ⏳ Implement Read Processor
6. ⏳ Implement Query API
7. ⏳ Implement Dashboard UI
8. ⏳ Add monitoring & observability
9. ⏳ Create load tests
10. ⏳ Record animated GIF demos

---

## Quick Reference

### Environment Variables
```bash
# Ledger API
NODE_ENV=development
PORT=4000
COCKROACH_HOST=localhost:26257
COCKROACH_DATABASE=chronicle
NATS_URL=nats://localhost:4222

# Read Processor
NATS_URL=nats://localhost:4222
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=chronicle
POSTGRES_PASSWORD=chronicle
POSTGRES_DB=chronicle_read

# Query API
PORT=4001
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=chronicle
POSTGRES_PASSWORD=chronicle
POSTGRES_DB=chronicle_read
```

---

## Current Step

**Waiting for Docker containers to start...**

Once ready, we'll:
1. Verify databases are initialized
2. Create TypeScript project structure for services
3. Implement the Ledger API first
4. Test with curl/Postman
5. Then build Read Processor, Query API, and Dashboard

---

**Status**: Infrastructure starting...  
**Next**: Verify Docker containers are healthy
