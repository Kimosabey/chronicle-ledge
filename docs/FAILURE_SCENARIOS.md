# 💥 ChronicleLedger Failure Scenarios

This document details the chaos engineering tests and failure scenarios ChronicleLedger is designed to withstand.

---

## 🧪 Scenario 1: CockroachDB Node Failure (High Availability)

**Test**: Kill one CockroachDB node in the 3-node cluster.
**Command**: `docker stop chronicle-cockroach-2`

**Expected Behavior**:
1. System continues to accept writes (2/3 quorum).
2. Use `GET /health` to see degraded status.
3. Restart node -> Data replicates back automatically.

**Result**: ✅ PASSED (Zero downtime)

---

## 🧪 Scenario 2: NATS Message Bus Failure (Eventual Consistency)

**Test**: stop NATS container.
**Command**: `docker stop chronicle-nats`

**Expected Behavior**:
1. **Writes**: Succeed (written to CockroachDB).
2. **Reads**: Lag (Read model stops updating).
3. **Recovery**: Restart NATS -> JetStream replays missed events -> Read model catches up.

**Result**: ✅ PASSED (No data loss, temporary consistency lag)

---

## 🧪 Scenario 3: Concurrent Withdrawals (Race Conditions)

**Test**: Send 100 concurrent withdrawal requests for $10 when balance is $100.
**Tool**: `k6` or `autocannon` script.

**Expected Behavior**:
1. 10 requests succeed.
2. 90 requests fail with `409 Conflict` (Optimistic Locking).
3. Final balance: $0 (Not negative).

**Result**: ✅ PASSED (Strict consistency maintained)

---

## 🧪 Scenario 4: Network Partition

**Test**: Simulate network split between Region A and Region B.
**Mechanism**: `iptables` rules.

**Expected Behavior**:
1. Partiton with majority (2 nodes) continues.
2. Partition with minority (1 node) rejects writes.
3. CP (Consistency) over AP (Availability) honored.

**Result**: ✅ PASSED (CAP Theorem alignment)

---

## 🧪 Scenario 5: Ledger API Crash

**Test**: Kill the Node.js API service mid-request.
**Command**: `docker kill chronicle-api`

**Expected Behavior**:
1. Load balancer routes to healthy instance.
2. If mid-transaction, client retries.
3. Idempotency keys prevent duplicate transactions on retry.

**Result**: ✅ PASSED

---

## 🚀 How to Run These Tests

```bash
# 1. Start System
docker-compose up -d

# 2. Run Chaos Script
./scripts/chaos-test.sh
```
