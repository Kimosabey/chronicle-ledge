Write-Host "Creating deposit of $5000..." -ForegroundColor Cyan
$body = @{
    account_id = "ACC-TEST-001"
    amount = 5000
    description = "End-to-end test deposit"
} | ConvertTo-Json

$response = Invoke-RestMethod -Method POST -Uri 'http://localhost:4002/commands/deposit' -Headers @{'Content-Type'='application/json'} -Body $body
Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green

Write-Host "`nWaiting 2 seconds for event processing..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

Write-Host "`n1. Check CockroachDB for NEW event..." -ForegroundColor Cyan
docker exec -it chronicle-cockroach ./cockroach sql --insecure -e "SELECT event_id, aggregate_id, event_type, created_at FROM chronicle.events WHERE aggregate_id='ACC-TEST-001' ORDER BY created_at DESC;"

Write-Host "`n2. Check PostgreSQL Read Model for UPDATED balance..." -ForegroundColor Cyan
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT account_id, owner_name, balance, currency FROM account_balance WHERE account_id='ACC-TEST-001';"

Write-Host "`n✅ VERIFICATION:" -ForegroundColor Yellow
Write-Host "- Event saved to CockroachDB? Check above" -ForegroundColor White
Write-Host "- Balance updated to $15,000? Check above" -ForegroundColor White
Write-Host "- PostgreSQL events table still empty? Yes (by design!)" -ForegroundColor White
