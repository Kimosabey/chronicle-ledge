# DBeaver Connection Guide - ChronicleLedger

## ✅ Connection Settings

Use these **exact** settings in DBeaver:

```
Connection Type: PostgreSQL
Host:           localhost
Port:           5432
Database:       chronicle
Username:       chronicle
Password:       chronicle
```

---

## 📋 Step-by-Step

### 1. Create New Connection
- Click **Database** → **New Database Connection**
- Select **PostgreSQL**
- Click **Next**

### 2. Main Tab Settings
```
Host:         localhost
Port:         5432
Database:     chronicle
Authentication: Database Native
Username:     chronicle
Password:     chronicle
☑ Save password
```

### 3. SSL Tab (Important!)
```
☐ Use SSL (UNCHECK THIS!)
```
**Note**: Our dev database doesn't use SSL

### 4. Test Connection
- Click **Test Connection**
- Should show: "Connected (PostgreSQL 16.x)"
- If driver missing, click **Download**

---

## 🔧 Troubleshooting

### Error: "password authentication failed"

**Solution 1**: Double-check password
- Password is exactly: `chronicle` (lowercase, no spaces)
- Username is exactly: `chronicle` (lowercase, no spaces)

**Solution 2**: Verify container is running
```bash
docker ps | findstr chronicle-db
# Should show: chronicle-db running
```

**Solution 3**: Check if port 5432 is accessible
```bash
# In PowerShell
Test-NetConnection -ComputerName localhost -Port 5432
```

**Solution 4**: Restart Docker container
```bash
docker-compose restart
```

---

## ✅ Once Connected

You'll see these tables:
- `events` (event store)
- `aggregate_versions` (versioning)
- `idempotency_keys` (deduplication)
- `account_balance` (read model)
- `transactions` (history)
- `transfers` (transfer tracking)
- `event_position` (processor state)

---

## 🔍 Test Queries

Once connected, try these:

```sql
-- Check all tables
SELECT tablename FROM pg_tables WHERE schemaname = 'public';

-- View events
SELECT * FROM events;

-- View accounts
SELECT * FROM account_balance;

-- Count records
SELECT 
    (SELECT COUNT(*) FROM events) as event_count,
    (SELECT COUNT(*) FROM account_balance) as account_count;
```

---

## 🎯 Quick Connection Test

Try this from command line first:
```bash
docker exec -it chronicle-db psql -U chronicle -d chronicle
```

If this works but DBeaver doesn't:
1. Check DBeaver's PostgreSQL driver version
2. Try updating the driver
3. Restart DBeaver

---

**Credentials Summary**:
- **Host**: localhost
- **Port**: 5432
- **Database**: chronicle
- **User**: chronicle
- **Password**: chronicle
- **SSL**: OFF
