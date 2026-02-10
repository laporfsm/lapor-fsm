# API Test Script for Lapor FSM Registration
# Usage: .\test-api.ps1 [undip|nonundip|undip-lecturer|test-login|verify-email|resend-verification]
#
# Examples:
#   .\test-api.ps1 undip           # Test UNDIP email registration
#   .\test-api.ps1 nonundip        # Test non-UNDIP email registration
#   .\test-api.ps1 test-login      # Test login

param(
    [Parameter(Mandatory=$false)]
    [string]$Command = "help",
    
    [Parameter(Mandatory=$false)]
    [string]$Email = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Password = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Token = ""
)

$BaseUrl = if ($env:API_URL) { $env:API_URL } else { "http://localhost:3000" }
$Timestamp = Get-Date -Format "yyyyMMddHHmmss"

function Test-UndipRegistration {
    Write-Host "📧 Testing UNDIP Email Registration (Auto-verified)" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    
    $body = @{
        name = "Test Student"
        email = "test$Timestamp@students.undip.ac.id"
        password = "password123"
        phone = "081234567890"
        nimNip = "24060122130001"
        department = "Informatika"
        faculty = "Sains dan Matematika"
        emergencyName = "Emergency Contact"
        emergencyPhone = "081234567891"
        address = "Jl. Test No. 123"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/auth/register" -Method POST -ContentType "application/json" -Body $body
        $response | ConvertTo-Json -Depth 10
        Write-Host ""
        Write-Host "✅ Expected: needsEmailVerification = false" -ForegroundColor Green
        Write-Host "✅ Expected: needsAdminApproval = false" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
        $_.Exception.Response | ConvertTo-Json -Depth 10
    }
}

function Test-NonUndipRegistration {
    Write-Host "📧 Testing Non-UNDIP Email Registration (Requires verification)" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    
    $body = @{
        name = "Test External User"
        email = "test$Timestamp@gmail.com"
        password = "password123"
        phone = "081234567890"
        nimNip = "EXTERNAL001"
        department = "Informatika"
        faculty = "Sains dan Matematika"
        emergencyName = "Emergency Contact"
        emergencyPhone = "081234567891"
        address = "Jl. Test No. 123"
        idCardUrl = "https://example.com/idcard.jpg"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/auth/register" -Method POST -ContentType "application/json" -Body $body
        $response | ConvertTo-Json -Depth 10
        Write-Host ""
        Write-Host "✅ Expected: needsEmailVerification = true" -ForegroundColor Yellow
        Write-Host "✅ Expected: needsAdminApproval = true" -ForegroundColor Yellow
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
    }
}

function Test-UndipLecturerRegistration {
    Write-Host "📧 Testing UNDIP Lecturer Email" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    
    $body = @{
        name = "Test Lecturer"
        email = "dosen$Timestamp@lecturer.undip.ac.id"
        password = "password123"
        phone = "081234567890"
        nimNip = "198501011999"
        department = "Fisika"
        faculty = "Sains dan Matematika"
        emergencyName = "Emergency Contact"
        emergencyPhone = "081234567891"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/auth/register" -Method POST -ContentType "application/json" -Body $body
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
    }
}

function Test-Login {
    param($TestEmail, $TestPassword)
    
    if (-not $TestEmail) { $TestEmail = "test@students.undip.ac.id" }
    if (-not $TestPassword) { $TestPassword = "password123" }
    
    Write-Host "🔑 Testing Login with: $TestEmail" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    
    $body = @{
        email = $TestEmail
        password = $TestPassword
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/auth/login" -Method POST -ContentType "application/json" -Body $body
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $errorBody = $reader.ReadToEnd()
            Write-Host "Response: $errorBody" -ForegroundColor Red
        }
    }
}

function Test-VerifyEmail {
    param($TestEmail, $TestToken)
    
    if (-not $TestEmail) { $TestEmail = "test@gmail.com" }
    if (-not $TestToken) { $TestToken = "123456" }
    
    Write-Host "✉️ Testing Email Verification" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    
    $body = @{
        email = $TestEmail
        token = $TestToken
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/auth/verify-email" -Method POST -ContentType "application/json" -Body $body
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
    }
}

function Test-ResendVerification {
    param($TestEmail)
    
    if (-not $TestEmail) { $TestEmail = "test@gmail.com" }
    
    Write-Host "🔄 Resending Verification Code" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    
    $body = @{
        email = $TestEmail
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/auth/resend-verification" -Method POST -ContentType "application/json" -Body $body
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
    }
}

function Show-Help {
    Write-Host @"
🧪 Lapor FSM API Test Script

Usage: .\test-api.ps1 [Command] [Options]

Commands:
  undip                    - Register with UNDIP student email (auto-verified)
  undip-lecturer           - Register with UNDIP lecturer email  
  nonundip                 - Register with non-UNDIP email (needs verification)
  test-login [email] [password]     - Test login
  verify-email [email] [token]      - Verify email with token
  resend-verification [email]       - Resend verification code

Environment Variables:
  API_URL                  - Base API URL (default: http://localhost:3000)

Examples:
  .\test-api.ps1 undip
  .\test-api.ps1 nonundip
  .\test-api.ps1 test-login test@students.undip.ac.id password123
  .\test-api.ps1 verify-email test@gmail.com 123456
"@ -ForegroundColor Yellow
}

# Main execution
Write-Host "🧪 Testing Registration API" -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Gray

switch ($Command.ToLower()) {
    "undip" { Test-UndipRegistration }
    "nonundip" { Test-NonUndipRegistration }
    "undip-lecturer" { Test-UndipLecturerRegistration }
    "test-login" { Test-Login -TestEmail $Email -TestPassword $Password }
    "verify-email" { Test-VerifyEmail -TestEmail $Email -TestToken $Token }
    "resend-verification" { Test-ResendVerification -TestEmail $Email }
    default { Show-Help }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Gray
Write-Host "✨ Test completed!" -ForegroundColor Green
