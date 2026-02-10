@echo off
chcp 65001 >nul

REM ============================================
REM API Test Script for Lapor FSM Registration
REM ============================================
REM Usage: test-api.bat [undip|nonundip|undip-lecturer|test-login|verify-email|resend-verification]
REM
REM Examples:
REM   test-api.bat undip      - Test UNDIP email registration
REM   test-api.bat nonundip   - Test non-UNDIP email registration
REM   test-api.bat test-login test@students.undip.ac.id password123
REM ============================================

set BASE_URL=%API_URL%
if "%BASE_URL%"=="" set BASE_URL=http://localhost:3000

for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set datetime=%%a
set TIMESTAMP=%datetime:~0,14%

echo 🧪 Testing Registration API
echo Base URL: %BASE_URL%
echo ============================================

if "%1"=="undip" goto :UNDIP
if "%1"=="nonundip" goto :NONUNDIP
if "%1"=="undip-lecturer" goto :UNDIP_LECTURER
if "%1"=="test-login" goto :TEST_LOGIN
if "%1"=="verify-email" goto :VERIFY_EMAIL
if "%1"=="resend-verification" goto :RESEND_VERIFICATION
goto :HELP

:UNDIP
echo 📧 Testing UNDIP Email Registration (Auto-verified)
echo ----------------------------------------
curl -X POST "%BASE_URL%/auth/register" ^
  -H "Content-Type: application/json" ^
  -d "{" ^
    "\"name\": \"Test Student\"," ^
    "\"email\": \"test%TIMESTAMP%@students.undip.ac.id\"," ^
    "\"password\": \"password123\"," ^
    "\"phone\": \"081234567890\"," ^
    "\"nimNip\": \"24060122130001\"," ^
    "\"department\": \"Informatika\"," ^
    "\"faculty\": \"Sains dan Matematika\"," ^
    "\"emergencyName\": \"Emergency Contact\"," ^
    "\"emergencyPhone\": \"081234567891\"," ^
    "\"address\": \"Jl. Test No. 123\"" ^
  "}"
echo.
echo ✅ Expected: needsEmailVerification = false
echo ✅ Expected: needsAdminApproval = false
goto :END

:NONUNDIP
echo 📧 Testing Non-UNDIP Email Registration (Requires verification)
echo ----------------------------------------
curl -X POST "%BASE_URL%/auth/register" ^
  -H "Content-Type: application/json" ^
  -d "{" ^
    "\"name\": \"Test External User\"," ^
    "\"email\": \"test%TIMESTAMP%@gmail.com\"," ^
    "\"password\": \"password123\"," ^
    "\"phone\": \"081234567890\"," ^
    "\"nimNip\": \"EXTERNAL001\"," ^
    "\"department\": \"Informatika\"," ^
    "\"faculty\": \"Sains dan Matematika\"," ^
    "\"emergencyName\": \"Emergency Contact\"," ^
    "\"emergencyPhone\": \"081234567891\"," ^
    "\"address\": \"Jl. Test No. 123\"," ^
    "\"idCardUrl\": \"https://example.com/idcard.jpg\"" ^
  "}"
echo.
echo ✅ Expected: needsEmailVerification = true
echo ✅ Expected: needsAdminApproval = true
goto :END

:UNDIP_LECTURER
echo 📧 Testing UNDIP Lecturer Email
echo ----------------------------------------
curl -X POST "%BASE_URL%/auth/register" ^
  -H "Content-Type: application/json" ^
  -d "{" ^
    "\"name\": \"Test Lecturer\"," ^
    "\"email\": \"dosen%TIMESTAMP%@lecturer.undip.ac.id\"," ^
    "\"password\": \"password123\"," ^
    "\"phone\": \"081234567890\"," ^
    "\"nimNip\": \"198501011999\"," ^
    "\"department\": \"Fisika\"," ^
    "\"faculty\": \"Sains dan Matematika\"," ^
    "\"emergencyName\": \"Emergency Contact\"," ^
    "\"emergencyPhone\": \"081234567891\"" ^
  "}"
goto :END

:TEST_LOGIN
set EMAIL=%2
set PASSWORD=%3
if "%EMAIL%"=="" set EMAIL=test@students.undip.ac.id
if "%PASSWORD%"=="" set PASSWORD=password123
echo 🔑 Testing Login with: %EMAIL%
echo ----------------------------------------
curl -X POST "%BASE_URL%/auth/login" ^
  -H "Content-Type: application/json" ^
  -d "{" ^
    "\"email\": \"%EMAIL%\"," ^
    "\"password\": \"%PASSWORD%\"" ^
  "}"
goto :END

:VERIFY_EMAIL
set EMAIL=%2
set TOKEN=%3
if "%EMAIL%"=="" set EMAIL=test@gmail.com
if "%TOKEN%"=="" set TOKEN=123456
echo ✉️ Testing Email Verification
echo ----------------------------------------
curl -X POST "%BASE_URL%/auth/verify-email" ^
  -H "Content-Type: application/json" ^
  -d "{" ^
    "\"email\": \"%EMAIL%\"," ^
    "\"token\": \"%TOKEN%\"" ^
  "}"
goto :END

:RESEND_VERIFICATION
set EMAIL=%2
if "%EMAIL%"=="" set EMAIL=test@gmail.com
echo 🔄 Resending Verification Code
echo ----------------------------------------
curl -X POST "%BASE_URL%/auth/resend-verification" ^
  -H "Content-Type: application/json" ^
  -d "{" ^
    "\"email\": \"%EMAIL%\"" ^
  "}"
goto :END

:HELP
echo ❌ Usage: %0 [undip^|nonundip^|undip-lecturer^|test-login^|verify-email^|resend-verification]
echo.
echo Commands:
echo   undip              - Register with UNDIP student email (auto-verified)
echo   undip-lecturer     - Register with UNDIP lecturer email
echo   nonundip           - Register with non-UNDIP email (needs verification)
echo   test-login [email] [password]  - Test login
echo   verify-email [email] [token]   - Verify email with token
echo   resend-verification [email]    - Resend verification code
echo.
echo Environment Variables:
echo   API_URL            - Base API URL (default: http://localhost:3000)
goto :END

:END
echo.
echo ============================================
echo ✨ Test completed!
pause
