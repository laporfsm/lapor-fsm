#!/bin/bash

# ============================================
# API Test Script for Lapor FSM Registration
# ============================================
# Usage: ./test-api.sh [undip|nonundip|cleanup]
#
# Examples:
#   ./test-api.sh undip      # Test UNDIP email registration
#   ./test-api.sh nonundip   # Test non-UNDIP email registration
#   ./test-api.sh cleanup    # Delete test users from database
# ============================================

BASE_URL="${API_URL:-http://localhost:3000}"
TIMESTAMP=$(date +%s)

echo "🧪 Testing Registration API"
echo "Base URL: $BASE_URL"
echo "============================================"

case "$1" in
  undip)
    echo "📧 Testing UNDIP Email Registration (Auto-verified)"
    echo "----------------------------------------"
    curl -X POST "$BASE_URL/auth/register" \
      -H "Content-Type: application/json" \
      -d "{
        \"name\": \"Test Student\",
        \"email\": \"test$TIMESTAMP@students.undip.ac.id\",
        \"password\": \"password123\",
        \"phone\": \"081234567890\",
        \"nimNip\": \"24060122130001\",
        \"department\": \"Informatika\",
        \"faculty\": \"Sains dan Matematika\",
        \"emergencyName\": \"Emergency Contact\",
        \"emergencyPhone\": \"081234567891\",
        \"address\": \"Jl. Test No. 123\"
      }" | jq .
    
    echo ""
    echo "✅ Expected: needsEmailVerification = false"
    echo "✅ Expected: needsAdminApproval = false"
    ;;

  nonundip)
    echo "📧 Testing Non-UNDIP Email Registration (Requires verification)"
    echo "----------------------------------------"
    curl -X POST "$BASE_URL/auth/register" \
      -H "Content-Type: application/json" \
      -d "{
        \"name\": \"Test External User\",
        \"email\": \"test$TIMESTAMP@gmail.com\",
        \"password\": \"password123\",
        \"phone\": \"081234567890\",
        \"nimNip\": \"EXTERNAL001\",
        \"department\": \"Informatika\",
        \"faculty\": \"Sains dan Matematika\",
        \"emergencyName\": \"Emergency Contact\",
        \"emergencyPhone\": \"081234567891\",
        \"address\": \"Jl. Test No. 123\",
        \"idCardUrl\": \"https://example.com/idcard.jpg\"
      }" | jq .
    
    echo ""
    echo "✅ Expected: needsEmailVerification = true"
    echo "✅ Expected: needsAdminApproval = true"
    ;;

  undip-lecturer)
    echo "📧 Testing UNDIP Lecturer Email"
    echo "----------------------------------------"
    curl -X POST "$BASE_URL/auth/register" \
      -H "Content-Type: application/json" \
      -d "{
        \"name\": \"Test Lecturer\",
        \"email\": \"dosen$TIMESTAMP@lecturer.undip.ac.id\",
        \"password\": \"password123\",
        \"phone\": \"081234567890\",
        \"nimNip\": \"198501011999\",
        \"department\": \"Fisika\",
        \"faculty\": \"Sains dan Matematika\",
        \"emergencyName\": \"Emergency Contact\",
        \"emergencyPhone\": \"081234567891\"
      }" | jq .
    ;;

  test-login)
    EMAIL="${2:-test@students.undip.ac.id}"
    PASSWORD="${3:-password123}"
    echo "🔑 Testing Login with: $EMAIL"
    echo "----------------------------------------"
    curl -X POST "$BASE_URL/auth/login" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$EMAIL\",
        \"password\": \"$PASSWORD\"
      }" | jq .
    ;;

  verify-email)
    EMAIL="${2:-test@gmail.com}"
    TOKEN="${3:-123456}"
    echo "✉️ Testing Email Verification"
    echo "----------------------------------------"
    curl -X POST "$BASE_URL/auth/verify-email" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$EMAIL\",
        \"token\": \"$TOKEN\"
      }" | jq .
    ;;

  resend-verification)
    EMAIL="${2:-test@gmail.com}"
    echo "🔄 Resending Verification Code"
    echo "----------------------------------------"
    curl -X POST "$BASE_URL/auth/resend-verification" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$EMAIL\"
      }" | jq .
    ;;

  *)
    echo "❌ Usage: $0 [undip|nonundip|undip-lecturer|test-login|verify-email|resend-verification]"
    echo ""
    echo "Commands:"
    echo "  undip              - Register with UNDIP student email (auto-verified)"
    echo "  undip-lecturer     - Register with UNDIP lecturer email"
    echo "  nonundip           - Register with non-UNDIP email (needs verification)"
    echo "  test-login [email] [password]  - Test login"
    echo "  verify-email [email] [token]   - Verify email with token"
    echo "  resend-verification [email]    - Resend verification code"
    echo ""
    echo "Environment Variables:"
    echo "  API_URL            - Base API URL (default: http://localhost:3000)"
    exit 1
    ;;
esac

echo ""
echo "============================================"
echo "✨ Test completed!"
