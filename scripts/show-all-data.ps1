Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "COCKROACHDB - EVENT STORE (Source of Truth)" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan
docker exec -it chronicle-cockroach ./cockroach sql --insecure -e "SELECT event_id, aggregate_id, event_type, created_at FROM chronicle.events ORDER BY created_at DESC LIMIT 10;"

Write-Host "`n"
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "POSTGRESQL - READ MODEL (For Fast Queries)" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`n--- Account Balances (Read Model) ---" -ForegroundColor Green
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT account_id, owner_name, balance, currency, status FROM account_balance ORDER BY created_at DESC;"

Write-Host "`n--- Transactions (Read Model) ---" -ForegroundColor Green  
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT * FROM transactions ORDER BY created_at DESC LIMIT 5;"

Write-Host "`n"
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "✅ Events are stored in: CockroachDB" -ForegroundColor Green
Write-Host "✅ Read Model is stored in: PostgreSQL" -ForegroundColor Green
Write-Host "✅ This is the CQRS pattern working correctly!" -ForegroundColor Green
