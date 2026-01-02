# DBeaver Connection Guide for Chronicle Ledger

## Quick Overview
Chronicle Ledger uses **two databases**:
- **PostgreSQL** (Port 5433): Read Model - Current account states
- **CockroachDB** (Port 26257): Event Store - Immutable event log

---

## 📋 Connection 1: PostgreSQL (Read Model)

### Connection Details
```
Driver:   PostgreSQL
Host:     localhost
Port:     5433
Database: chronicle
Username: chronicle
Password: chronicle
```

### Step-by-Step Setup in DBeaver
1. Click **"Database"** → **"New Database Connection"**
2. Select **PostgreSQL** from the list
3. Click **"Next"**
4. Enter the details:
   - **Host**: `localhost`
   - **Port**: `5433`
   - **Database**: `chronicle`
   - **Username**: `chronicle`
   - **Password**: `chronicle`
5. Click **"Test Connection"** → Should show "Connected"
6. Click **"Finish"**

### What You'll See
Tables in this database:
- `account_balance` - Current account states (materialized view)
- `transactions` - Transaction history
- `transfers` - Transfer records
- `event_position` - Last processed event tracker

---

## 📋 Connection 2: CockroachDB (Event Store)

### Connection Details
```
Driver:   PostgreSQL (CockroachDB uses Postgres wire protocol)
Host:     localhost
Port:     26257
Database: chronicle
Username: root
Password: (leave empty)
SSL:      Disabled
```

### Step-by-Step Setup in DBeaver
1. Click **"Database"** → **"New Database Connection"**
2. Select **PostgreSQL** from the list
3. Click **"Next"**
4. Enter the details:
   - **Host**: `localhost`
   - **Port**: `26257`
   - **Database**: `chronicle`
   - **Username**: `root`
   - **Password**: *(leave empty)*
5. Click on **"Driver properties"** tab at the bottom
6. Find **"ssl"** property and set it to **`false`** or **`disable`**
7. Click **"Test Connection"** → Should show "Connected"
8. Click **"Finish"**

### What You'll See
Tables in this database:
- `events` - Immutable event log (append-only)
- `aggregate_versions` - Version tracking for optimistic locking
- `snapshots` - Performance optimization snapshots
- `idempotency_keys` - Prevent duplicate writes

---

## 🎯 Quick Test Queries

### PostgreSQL (Read Model)
```sql
-- Check all accounts
SELECT * FROM account_balance;

-- Check transactions
SELECT * FROM transactions ORDER BY timestamp DESC;
```

### CockroachDB (Event Store)
```sql
-- Check all events
SELECT * FROM events ORDER BY created_at DESC;

-- Check events for specific account
SELECT * FROM events WHERE aggregate_id = 'ACC-001' ORDER BY created_at;
```

---

## 🔍 Troubleshooting

### PostgreSQL Connection Issues
- **Error**: "Connection refused"
  - **Fix**: Ensure Docker container is running: `docker ps | grep chronicle-db`
  - **Fix**: Verify port 5433 is mapped: `docker port chronicle-db`

### CockroachDB Connection Issues
- **Error**: "SSL required"
  - **Fix**: Disable SSL in driver properties (step 6 above)
  
- **Error**: "Authentication failed"
  - **Fix**: Use username `root` with no password (it's running in insecure mode)

- **Error**: "Connection refused"
  - **Fix**: Ensure Docker container is running: `docker ps | grep chronicle-cockroach`
  - **Fix**: Check CockroachDB is healthy: `docker logs chronicle-cockroach`

---

## 💡 Pro Tips

1. **Create a Project Folder**: In DBeaver, create a "Chronicle Ledger" project folder and add both connections to it
2. **Color Code**: Right-click connections → Properties → Connection → Set different colors (e.g., Green for Postgres, Blue for CockroachDB)
3. **Bookmarks**: Save your frequently used queries as SQL scripts or bookmarks
4. **Auto-Refresh**: Enable auto-refresh on the tables to see real-time updates

---

## ✅ Verification

Once connected, run these queries to verify everything is set up:

**PostgreSQL:**
```sql
SELECT 'PostgreSQL Read Model' as db, COUNT(*) as table_count 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

**CockroachDB:**
```sql
SELECT 'CockroachDB Event Store' as db, COUNT(*) as table_count 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

Both should return a count of tables (4 tables in each).

---

**Need help?** Check `docker ps` to ensure both `chronicle-db` and `chronicle-cockroach` are running.
