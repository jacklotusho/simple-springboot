#!/bin/bash

# Script to test CA setup and verify all components
# Usage: ./test-ca-setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CA_ROOT_DIR="../ca/root-ca"
CA_INTERMEDIATE_DIR="../ca/intermediate-ca"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    print_test "$test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Start testing
print_header "=========================================="
print_header "  CA Setup Verification Tests"
print_header "=========================================="
echo ""

# Test 1: Check if OpenSSL is installed
print_header "1. Checking Prerequisites"
echo ""
run_test "OpenSSL is installed" "command -v openssl"

if command -v openssl > /dev/null 2>&1; then
    OPENSSL_VERSION=$(openssl version)
    print_info "OpenSSL version: $OPENSSL_VERSION"
fi
echo ""

# Test 2: Check Root CA directory structure
print_header "2. Checking Root CA Directory Structure"
echo ""
run_test "Root CA directory exists" "[ -d '$CA_ROOT_DIR' ]"
run_test "Root CA private directory exists" "[ -d '$CA_ROOT_DIR/private' ]"
run_test "Root CA certs directory exists" "[ -d '$CA_ROOT_DIR/certs' ]"
run_test "Root CA newcerts directory exists" "[ -d '$CA_ROOT_DIR/newcerts' ]"
run_test "Root CA crl directory exists" "[ -d '$CA_ROOT_DIR/crl' ]"
run_test "Root CA index.txt exists" "[ -f '$CA_ROOT_DIR/index.txt' ]"
run_test "Root CA serial file exists" "[ -f '$CA_ROOT_DIR/serial' ]"
run_test "Root CA openssl.cnf exists" "[ -f '$CA_ROOT_DIR/openssl.cnf' ]"
echo ""

# Test 3: Check Root CA certificate
print_header "3. Checking Root CA Certificate"
echo ""
run_test "Root CA private key exists" "[ -f '$CA_ROOT_DIR/private/ca.key.pem' ]"
run_test "Root CA certificate exists" "[ -f '$CA_ROOT_DIR/certs/ca.cert.pem' ]"

if [ -f "$CA_ROOT_DIR/certs/ca.cert.pem" ]; then
    run_test "Root CA certificate is valid" "openssl x509 -noout -text -in '$CA_ROOT_DIR/certs/ca.cert.pem'"
    
    print_info "Root CA Certificate Details:"
    openssl x509 -noout -subject -issuer -dates -in "$CA_ROOT_DIR/certs/ca.cert.pem" | sed 's/^/  /'
fi
echo ""

# Test 4: Check Intermediate CA directory structure
print_header "4. Checking Intermediate CA Directory Structure"
echo ""
run_test "Intermediate CA directory exists" "[ -d '$CA_INTERMEDIATE_DIR' ]"
run_test "Intermediate CA private directory exists" "[ -d '$CA_INTERMEDIATE_DIR/private' ]"
run_test "Intermediate CA certs directory exists" "[ -d '$CA_INTERMEDIATE_DIR/certs' ]"
run_test "Intermediate CA csr directory exists" "[ -d '$CA_INTERMEDIATE_DIR/csr' ]"
run_test "Intermediate CA newcerts directory exists" "[ -d '$CA_INTERMEDIATE_DIR/newcerts' ]"
run_test "Intermediate CA crl directory exists" "[ -d '$CA_INTERMEDIATE_DIR/crl' ]"
run_test "Intermediate CA index.txt exists" "[ -f '$CA_INTERMEDIATE_DIR/index.txt' ]"
run_test "Intermediate CA serial file exists" "[ -f '$CA_INTERMEDIATE_DIR/serial' ]"
run_test "Intermediate CA openssl.cnf exists" "[ -f '$CA_INTERMEDIATE_DIR/openssl.cnf' ]"
echo ""

# Test 5: Check Intermediate CA certificate
print_header "5. Checking Intermediate CA Certificate"
echo ""
run_test "Intermediate CA private key exists" "[ -f '$CA_INTERMEDIATE_DIR/private/intermediate.key.pem' ]"
run_test "Intermediate CA certificate exists" "[ -f '$CA_INTERMEDIATE_DIR/certs/intermediate.cert.pem' ]"
run_test "CA chain certificate exists" "[ -f '$CA_INTERMEDIATE_DIR/certs/ca-chain.cert.pem' ]"

if [ -f "$CA_INTERMEDIATE_DIR/certs/intermediate.cert.pem" ]; then
    run_test "Intermediate CA certificate is valid" "openssl x509 -noout -text -in '$CA_INTERMEDIATE_DIR/certs/intermediate.cert.pem'"
    
    print_info "Intermediate CA Certificate Details:"
    openssl x509 -noout -subject -issuer -dates -in "$CA_INTERMEDIATE_DIR/certs/intermediate.cert.pem" | sed 's/^/  /'
fi
echo ""

# Test 6: Verify certificate chain
print_header "6. Verifying Certificate Chain"
echo ""
if [ -f "$CA_INTERMEDIATE_DIR/certs/intermediate.cert.pem" ] && [ -f "$CA_ROOT_DIR/certs/ca.cert.pem" ]; then
    run_test "Intermediate certificate is signed by Root CA" "openssl verify -CAfile '$CA_ROOT_DIR/certs/ca.cert.pem' '$CA_INTERMEDIATE_DIR/certs/intermediate.cert.pem'"
fi
echo ""

# Test 7: Check file permissions
print_header "7. Checking File Permissions"
echo ""
if [ -f "$CA_ROOT_DIR/private/ca.key.pem" ]; then
    PERMS=$(stat -f "%Lp" "$CA_ROOT_DIR/private/ca.key.pem" 2>/dev/null || stat -c "%a" "$CA_ROOT_DIR/private/ca.key.pem" 2>/dev/null)
    if [ "$PERMS" = "400" ]; then
        echo -e "  ${GREEN}✓ PASSED${NC} Root CA private key has correct permissions (400)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${YELLOW}⚠ WARNING${NC} Root CA private key permissions: $PERMS (should be 400)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
fi

if [ -f "$CA_INTERMEDIATE_DIR/private/intermediate.key.pem" ]; then
    PERMS=$(stat -f "%Lp" "$CA_INTERMEDIATE_DIR/private/intermediate.key.pem" 2>/dev/null || stat -c "%a" "$CA_INTERMEDIATE_DIR/private/intermediate.key.pem" 2>/dev/null)
    if [ "$PERMS" = "400" ]; then
        echo -e "  ${GREEN}✓ PASSED${NC} Intermediate CA private key has correct permissions (400)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${YELLOW}⚠ WARNING${NC} Intermediate CA private key permissions: $PERMS (should be 400)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
fi
echo ""

# Test 8: Check for issued certificates
print_header "8. Checking Issued Certificates"
echo ""
if [ -f "$CA_INTERMEDIATE_DIR/index.txt" ]; then
    CERT_COUNT=$(wc -l < "$CA_INTERMEDIATE_DIR/index.txt" | tr -d ' ')
    print_info "Total certificates issued: $CERT_COUNT"
    
    if [ "$CERT_COUNT" -gt 0 ]; then
        VALID_CERTS=$(grep -c "^V" "$CA_INTERMEDIATE_DIR/index.txt" || true)
        REVOKED_CERTS=$(grep -c "^R" "$CA_INTERMEDIATE_DIR/index.txt" || true)
        print_info "Valid certificates: $VALID_CERTS"
        print_info "Revoked certificates: $REVOKED_CERTS"
    fi
fi
echo ""

# Test 9: Test certificate creation (optional)
print_header "9. Testing Certificate Creation (Optional)"
echo ""
print_warning "This test will create a test certificate. Continue? (yes/no)"
read -r CONFIRM

if [ "$CONFIRM" = "yes" ]; then
    TEST_DOMAIN="test-$(date +%s).example.com"
    print_info "Creating test certificate for: $TEST_DOMAIN"
    
    if ./create-server-cert.sh "$TEST_DOMAIN" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ PASSED${NC} Test certificate created successfully"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # Verify the test certificate
        if openssl verify -CAfile "$CA_INTERMEDIATE_DIR/certs/ca-chain.cert.pem" "$CA_INTERMEDIATE_DIR/certs/$TEST_DOMAIN.cert.pem" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ PASSED${NC} Test certificate verification successful"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "  ${RED}✗ FAILED${NC} Test certificate verification failed"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        
        # Clean up test certificate
        print_info "Cleaning up test certificate..."
        rm -f "$CA_INTERMEDIATE_DIR/private/$TEST_DOMAIN.key.pem"
        rm -f "$CA_INTERMEDIATE_DIR/certs/$TEST_DOMAIN.cert.pem"
        rm -f "$CA_INTERMEDIATE_DIR/csr/$TEST_DOMAIN.csr.pem"
        
        # Remove from index.txt
        if [ -f "$CA_INTERMEDIATE_DIR/index.txt" ]; then
            grep -v "$TEST_DOMAIN" "$CA_INTERMEDIATE_DIR/index.txt" > "$CA_INTERMEDIATE_DIR/index.txt.tmp" || true
            mv "$CA_INTERMEDIATE_DIR/index.txt.tmp" "$CA_INTERMEDIATE_DIR/index.txt"
        fi
    else
        echo -e "  ${RED}✗ FAILED${NC} Test certificate creation failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 2))
else
    print_info "Skipping certificate creation test"
fi
echo ""

# Summary
print_header "=========================================="
print_header "  Test Summary"
print_header "=========================================="
echo ""
echo "Total tests: $TESTS_TOTAL"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    print_info "All tests passed! Your CA is properly configured."
    exit 0
else
    print_error "Some tests failed. Please review the output above."
    print_info "Refer to CA-SETUP.md for setup instructions."
    exit 1
fi

# Made with Bob
