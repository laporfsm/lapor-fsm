# Lapor FSM API Test Script
# Usage: .\test-api-simple.ps1 [undip|nonundip|login]

param([string]$cmd = "help", [string]$email = "", [string]$pass = "")

$url = if ($env:API_URL) { $env:API_URL } else { "http://localhost:3000" }
$ts = Get-Date -Format "yyyyMMddHHmmss"

Write-Host "API Test Script"
Write-Host "URL: $url"
Write-Host "================================"

if ($cmd -eq "undip") {
    Write-Host "Test 1: UNDIP Student Registration"
    Write-Host "--------------------------------"
    
    $json = @"
    {
        "name": "Test Student",
        "email": "test$ts@students.undip.ac.id",
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
        Write-Host "Expected: needsEmailVerification = false"
        Write-Host "Expected: needsAdminApproval = false"
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
elseif ($cmd -eq "nonundip") {
    Write-Host "Test 2: Non-UNDIP Registration"
    Write-Host "--------------------------------"
    
    $json = @"
    {
        "name": "Test External User",
        "email": "test$ts@gmail.com",
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
        Write-Host "Expected: needsEmailVerification = true"
        Write-Host "Expected: needsAdminApproval = true"
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
elseif ($cmd -eq "login") {
    if (-not $email) { $email = "test@students.undip.ac.id" }
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
else {
    Write-Host "Usage:"
    Write-Host "  .\test-api-simple.ps1 undip              - Test UNDIP registration"
    Write-Host "  .\test-api-simple.ps1 nonundip           - Test non-UNDIP registration"
    Write-Host "  .\test-api-simple.ps1 login [email] [pass] - Test login"
    Write-Host ""
    Write-Host "Environment:"
    Write-Host "  Set API_URL=http://localhost:3000"
}

Write-Host ""
Write-Host "================================"
Write-Host "Done!"
