Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "YOUR CHRONICLE LEDGER DATA - SIMPLE VIEW" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n📝 EVENTS (CockroachDB - The Source of Truth)" -ForegroundColor Green
Write-Host "-" * 80
docker exec -it chronicle-cockroach ./cockroach sql --insecure --format=table -e "SELECT LEFT(event_id::STRING, 8) as event_id, aggregate_id, event_type, to_char(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at FROM chronicle.events ORDER BY created_at DESC LIMIT 10;"

Write-Host "`n`n💰 ACCOUNTS (PostgreSQL - Current Balances)" -ForegroundColor Green
Write-Host "-" * 80
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT account_id, owner_name, balance, currency, status FROM account_balance ORDER BY created_at DESC;"

Write-Host "`n`n📊 TRANSACTIONS (PostgreSQL - Transaction History)" -ForegroundColor Green
Write-Host "-" * 80
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT transaction_id, account_id, amount, balance_after, description, to_char(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at FROM transactions ORDER BY created_at DESC LIMIT 5;"

Write-Host "`n`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "✅ OPEN THESE URLs IN YOUR BROWSER:" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "🌐 Dashboard (Events UI):    http://localhost:3000" -ForegroundColor White
Write-Host "🪳 CockroachDB UI:            http://localhost:8080" -ForegroundColor White
Write-Host "📊 NATS Monitor:              http://localhost:8222" -ForegroundColor White

Write-Host "`n🔍 TO SEE DATA IN DBeaver:" -ForegroundColor Yellow
Write-Host "   1. Connect to PostgreSQL (localhost:5433)" -ForegroundColor White
Write-Host "   2. Navigate to: chronicle -> Schemas -> public -> Tables" -ForegroundColor White
Write-Host "   3. Right-click 'account_balance' -> View Data" -ForegroundColor White
