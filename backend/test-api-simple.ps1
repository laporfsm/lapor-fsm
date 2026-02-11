# Lapor FSM API Test Script
# Usage: .\test-api-simple.ps1 [undip|nonundip|login]

param([string]$cmd = "help", [string]$email = "", [string]$pass = "")

$url = if ($env:API_URL) { $env:API_URL } else { "http://localhost:3000" }

Write-Host "API Test Script"
Write-Host "URL: $url"
Write-Host "================================"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"

if ($cmd -eq "undip") {
    Write-Host "Test 1: UNDIP Student Registration"
    $testEmail = "test_$timestamp@students.undip.ac.id"
    Write-Host "Email: $testEmail"
    Write-Host "--------------------------------"
    
    $json = @"
    {
        "name": "Sulhan Fuadi",
        "email": "$testEmail",
        "password": "password123",
        "phone": "081234567890",
        "nimNip": "24060122130001",
        "department": "Informatika",
        "faculty": "Sains dan Matematika",
        "emergencyName": "Emergency Contact",
        "emergencyPhone": "081234567891",
        "address": "Jl. Test No. 123"
    }
"@
    
    try {
        $res = Invoke-RestMethod -Uri "$url/auth/register" -Method POST -ContentType "application/json" -Body $json
        $res | ConvertTo-Json -Depth 10
        Write-Host ""
        Write-Host "Expected: needsEmailVerification = true"
        Write-Host "Expected: needsAdminApproval = false"
        Write-Host ""
        Write-Host "NOTE: Check your email (sulhanfuadi@students.undip.ac.id) for activation link"
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
elseif ($cmd -eq "nonundip") {
    Write-Host "Test 2: Non-UNDIP Registration"
    $testEmail = "test_$timestamp@gmail.com"
    Write-Host "Email: $testEmail"
    Write-Host "--------------------------------"
    
    $json = @"
    {
        "name": "Sulhan Fuadi Dev",
        "email": "$testEmail",
        "password": "password123",
        "phone": "081234567890",
        "nimNip": "EXTERNAL001",
        "department": "Informatika",
        "faculty": "Sains dan Matematika",
        "emergencyName": "Emergency Contact",
        "emergencyPhone": "081234567891",
        "address": "Jl. Test No. 123",
        "idCardUrl": "https://example.com/idcard.jpg"
    }
"@
    
    try {
        $res = Invoke-RestMethod -Uri "$url/auth/register" -Method POST -ContentType "application/json" -Body $json
        $res | ConvertTo-Json -Depth 10
        Write-Host ""
        Write-Host "Expected: needsEmailVerification = false"
        Write-Host "Expected: needsAdminApproval = true"
        Write-Host ""
        Write-Host "NOTE: No activation email sent yet. Waiting for admin approval."
        Write-Host "Use: curl -X POST $url/auth/admin/approve-user -H `"Content-Type: application/json`" -d '{`"userId`": <ID>}'"
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
elseif ($cmd -eq "login") {
    if (-not $email) { $email = "sulhanfuadi@students.undip.ac.id" }
    if (-not $pass) { $pass = "password123" }
    
    Write-Host "Test 3: Login"
    Write-Host "Email: $email"
    Write-Host "--------------------------------"
    
    $json = @"
    {
        "email": "$email",
        "password": "$pass"
    }
"@
    
    try {
        $res = Invoke-RestMethod -Uri "$url/auth/login" -Method POST -ContentType "application/json" -Body $json
        $res | ConvertTo-Json -Depth 10
        Write-Host ""
        Write-Host "Login successful! Token received."
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            Write-Host $reader.ReadToEnd() -ForegroundColor Red
        }
    }
}
elseif ($cmd -eq "approve") {
    $userId = if ($email) { $email } else { "42" }
    
    Write-Host "Test 4: Admin Approve User"
    Write-Host "UserID: $userId"
    Write-Host "--------------------------------"
    
    $json = @"
    {
        "userId": $userId
    }
"@
    
    try {
        $res = Invoke-RestMethod -Uri "$url/auth/admin/approve-user" -Method POST -ContentType "application/json" -Body $json
        $res | ConvertTo-Json -Depth 10
        Write-Host ""
        Write-Host "User approved! Activation email sent to sulhanfuadi.dev@gmail.com"
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "Usage:"
    Write-Host "  .\test-api-simple.ps1 undip              - Test UNDIP registration (sulhanfuadi@students.undip.ac.id)"
    Write-Host "  .\test-api-simple.ps1 nonundip           - Test non-UNDIP registration (sulhanfuadi.dev@gmail.com)"
    Write-Host "  .\test-api-simple.ps1 login [email] [pass] - Test login"
    Write-Host "  .\test-api-simple.ps1 approve [userId]   - Admin approve user"
    Write-Host ""
    Write-Host "Test Accounts:"
    Write-Host "  UNDIP:    sulhanfuadi@students.undip.ac.id"
    Write-Host "  External: sulhanfuadi.dev@gmail.com"
    Write-Host ""
    Write-Host "Environment:"
    Write-Host "  Set API_URL=http://localhost:3000"
}

Write-Host ""
Write-Host "================================"
Write-Host "Done!"
