# Test creating an account
$body = @{
    account_id = "ACC-TEST-001"
    owner_name = "Harsha Test"  
    initial_balance = 10000
    currency = "USD"
} | ConvertTo-Json

Write-Host "Creating account..." -ForegroundColor Cyan
$response = Invoke-RestMethod -Method POST -Uri 'http://localhost:4002/commands/create-account' -Headers @{'Content-Type'='application/json'} -Body $body
Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green

Write-Host "`nWaiting 2 seconds for event processing..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

Write-Host "`nChecking CockroachDB events..." -ForegroundColor Cyan
docker exec -it chronicle-cockroach ./cockroach sql --insecure -e "SELECT event_id, aggregate_id, event_type, created_at FROM chronicle.events ORDER BY created_at DESC LIMIT 5;"

Write-Host "`nChecking PostgreSQL events..." -ForegroundColor Cyan
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT event_id, aggregate_id, event_type, created_at FROM events ORDER BY created_at DESC LIMIT 5;"

Write-Host "`nChecking PostgreSQL read model..." -ForegroundColor Cyan
docker exec -it chronicle-db psql -U chronicle -d chronicle -c "SELECT * FROM account_balance WHERE account_id='ACC-TEST-001';"
