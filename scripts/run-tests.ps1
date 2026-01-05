# ChronicleLedger - Interactive Test Script
# Run this in PowerShell: .\run-tests.ps1

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  ChronicleLedger Test Suite" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Checks
Write-Host "[1/8] Testing service health..." -ForegroundColor Yellow
try {
    $ledgerHealth = Invoke-RestMethod -Uri "http://localhost:4000/health"
    Write-Host "✅ Ledger API: $($ledgerHealth.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Ledger API: Not responding" -ForegroundColor Red
}

try {
    $queryHealth = Invoke-RestMethod -Uri "http://localhost:4001/health"
    Write-Host "✅ Query API: $($queryHealth.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Query API: Not responding" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 1

# Test 2: Create Account
Write-Host "[2/8] Creating account ACC-001..." -ForegroundColor Yellow
$accountData = @{
    account_id = "ACC-001"
    owner_name = "Harshan Aiyappa"
    initial_balance = 5000
    currency = "USD"
} | ConvertTo-Json

try {
    $createResult = Invoke-RestMethod -Uri "http://localhost:4000/commands/create-account" -Method POST -ContentType "application/json" -Body $accountData
    Write-Host "✅ Account created! Event ID: $($createResult.event_id)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 3: Query Account
Write-Host "[3/8] Querying account balance..." -ForegroundColor Yellow
try {
    $account = Invoke-RestMethod -Uri "http://localhost:4001/accounts/ACC-001"
    Write-Host "✅ Balance: $($account.balance) $($account.currency)" -ForegroundColor Green
    Write-Host "   Owner: $($account.owner_name)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to query account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 1

# Test 4: Deposit Money
Write-Host "[4/8] Depositing $2500..." -ForegroundColor Yellow
$depositData = @{
    account_id = "ACC-001"
    amount = 2500
    description = "January Salary"
} | ConvertTo-Json

try {
    $depositResult = Invoke-RestMethod -Uri "http://localhost:4000/commands/deposit" -Method POST -ContentType "application/json" -Body $depositData
    Write-Host "✅ Deposit successful! Event ID: $($depositResult.event_id)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to deposit: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 5: Check New Balance
Write-Host "[5/8] Checking updated balance..." -ForegroundColor Yellow
try {
    $account = Invoke-RestMethod -Uri "http://localhost:4001/accounts/ACC-001"
    Write-Host "✅ New Balance: $($account.balance) $($account.currency)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to query: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 1

# Test 6: Create Second Account
Write-Host "[6/8] Creating second account ACC-002..." -ForegroundColor Yellow
$account2Data = @{
    account_id = "ACC-002"
    owner_name = "Alice Johnson"
    initial_balance = 1000
    currency = "USD"
} | ConvertTo-Json

try {
    $createResult2 = Invoke-RestMethod -Uri "http://localhost:4000/commands/create-account" -Method POST -ContentType "application/json" -Body $account2Data
    Write-Host "✅ Account created! Event ID: $($createResult2.event_id)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 7: Transfer Money
Write-Host "[7/8] Transferring $1500 from ACC-001 to ACC-002..." -ForegroundColor Yellow
$transferData = @{
    from_account_id = "ACC-001"
    to_account_id = "ACC-002"
    amount = 1500
    description = "Payment for consulting"
} | ConvertTo-Json

try {
    $transferResult = Invoke-RestMethod -Uri "http://localhost:4000/commands/transfer" -Method POST -ContentType "application/json" -Body $transferData
    Write-Host "✅ Transfer successful!" -ForegroundColor Green
    Write-Host "   Events created: $($transferResult.events.Count)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to transfer: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 8: Check Both Balances
Write-Host "[8/8] Checking final balances..." -ForegroundColor Yellow
try {
    $acc1 = Invoke-RestMethod -Uri "http://localhost:4001/accounts/ACC-001"
    $acc2 = Invoke-RestMethod -Uri "http://localhost:4001/accounts/ACC-002"
    Write-Host "✅ ACC-001: $($acc1.balance) USD" -ForegroundColor Green
    Write-Host "✅ ACC-002: $($acc2.balance) USD" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to query accounts" -ForegroundColor Red
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Test Suite Complete!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open browser: http://localhost:3000 (Dashboard)" -ForegroundColor White
Write-Host "  2. View events: curl http://localhost:4001/events" -ForegroundColor White
Write-Host "  3. Time-travel query: See TEST_COMMANDS.md" -ForegroundColor White
