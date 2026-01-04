# ⚡ ChronicleLedger - Quick Start Commands

> Copy-paste these commands to run the entire project in 5 minutes

---

## 🚀 **Step 1: Start Infrastructure**

```powershell
# Navigate to project
cd "g:\LearningRelated\Portfolio Project\chronicle-ledge"

# Check if Docker is running
docker ps

# Should see:
# chronicle-db (PostgreSQL) - Port 5433
# chronicle-nats (NATS) - Ports 4222/8222
```

---

## 📦 **Step 2: Install Dependencies**

```powershell
# Install all workspace dependencies
npm install

# This installs for:
# - Root project
# - services/ledger-api
# - services/query-api
# - services/read-processor
# - ui/dashboard
```

---

## ▶️ **Step 3: Start All Services**

```powershell
# Start everything at once
npm run dev

# This starts:
# [ledger-api] Port 4000 - Write commands
# [query-api] Port 4001 - Read queries
# [read-processor] NATS consumer
# [dashboard] Port 3000 - Web UI
```

---

## 🧪 **Step 4: Test the System**

### Create Account
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

### Query Account
```powershell
curl http://localhost:4001/accounts/ACC-001
```

### Deposit Money
```powershell
curl -X POST http://localhost:4000/commands/deposit `
  -H "Content-Type: application/json" `
  -d '{
    "account_id": "ACC-001",
    "amount": 500,
    "description": "Salary payment"
  }'
```

### Create Second Account
```powershell
curl -X POST http://localhost:4000/commands/create-account `
  -H "Content-Type: application/json" `
  -d '{
    "account_id": "ACC-002",
    "owner_name": "Bob Smith",
    "initial_balance": 500,
    "currency": "USD"
  }'
```

### Transfer Between Accounts
```powershell
curl -X POST http://localhost:4000/commands/transfer `
  -H "Content-Type: application/json" `
  -d '{
    "from_account_id": "ACC-001",
    "to_account_id": "ACC-002",
    "amount": 200,
    "description": "Payment for services"
  }'
```

### Time-Travel Query ⭐
```powershell
# Get current timestamp
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Do another deposit
curl -X POST http://localhost:4000/commands/deposit `
  -H "Content-Type: application/json" `
  -d '{"account_id":"ACC-001","amount":100,"description":"Bonus"}'

# Query current balance
curl http://localhost:4001/accounts/ACC-001

# Query PAST balance (before the deposit)
curl "http://localhost:4001/accounts/ACC-001/balance-at?timestamp=$timestamp"
```

### View All Events
```powershell
curl http://localhost:4001/events?limit=50
```

---

## 🎯 **Step 5: Run Automated Tests**

```powershell
# Run end-to-end test suite
node scripts/e2e-test.js
```

---

## 🌐 **Step 6: Open Dashboard**

Open in browser:
```
http://localhost:3000
```

Features:
- Real-time event stream
- Filter by event type
- Expandable JSON details
- Auto-refresh every 2 seconds

---

## 🔍 **Verification Commands**

### Check Service Health
```powershell
curl http://localhost:4000/health  # Ledger API
curl http://localhost:4001/health  # Query API
```

### Check Docker Containers
```powershell
docker ps
docker logs chronicle-db
docker logs chronicle-nats
```

### Check Database Tables
```powershell
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "\dt"
```

### View Event Store Data
```powershell
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT * FROM events ORDER BY created_at DESC LIMIT 10;"
```

### View Read Model Data
```powershell
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT * FROM account_balance;"
```

---

## 🛑 **Shutdown Commands**

### Stop Services (Keep Docker Running)
```powershell
# Press Ctrl+C in the terminal running npm run dev
```

### Stop Everything
```powershell
# Stop services
Ctrl+C

# Stop Docker containers
docker-compose down
```

### Clean Restart (Delete All Data)
```powershell
# Stop and remove volumes
docker-compose down -v

# Start fresh
docker-compose up -d
npm run dev
```

---

## 📊 **Useful Monitoring**

### Watch Event Stream
```powershell
# In a separate terminal
while ($true) {
  curl http://localhost:4001/events?limit=5
  Start-Sleep -Seconds 2
  Clear-Host
}
```

### Monitor NATS
```powershell
# Open in browser
http://localhost:8222

# View stats
curl http://localhost:8222/varz
```

---

## 🎓 **Demo Script for Recruiters**

1. **Show infrastructure** (10 seconds)
   ```powershell
   docker ps
   ```

2. **Start services** (10 seconds)
   ```powershell
   npm run dev
   ```

3. **Create account** (15 seconds)
   ```powershell
   curl -X POST http://localhost:4000/commands/create-account ...
   curl http://localhost:4001/accounts/ACC-001
   ```

4. **Time-travel demo** (30 seconds)
   ```powershell
   # Show current balance
   curl http://localhost:4001/accounts/ACC-001
   
   # Do transaction
   curl -X POST http://localhost:4000/commands/deposit ...
   
   # Show NEW balance
   curl http://localhost:4001/accounts/ACC-001
   
   # Show OLD balance (time-travel!)
   curl "http://localhost:4001/accounts/ACC-001/balance-at?timestamp=<BEFORE>"
   ```

5. **Show event log** (15 seconds)
   ```powershell
   curl http://localhost:4001/events
   ```

**Total demo time**: 90 seconds

---

## 🐛 **Common Issues**

### Issue: "concurrently: command not found"
```powershell
npm install
```

### Issue: "Cannot connect to PostgreSQL"
```powershell
docker-compose restart postgres
Start-Sleep -Seconds 10
```

### Issue: "Port already in use"
```powershell
# Find process using port 4000
Get-NetTCPConnection -LocalPort 4000 | Select-Object -ExpandProperty OwningProcess
# Kill it
Stop-Process -Id <PID>
```

---

**Ready to run?** Start with Step 1 and go! 🚀
