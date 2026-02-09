#!/bin/bash

# Script to list all issued certificates
# Usage: ./list-certs.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CA_DIR="../ca/intermediate-ca"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Check if CA directory exists
if [ ! -d "$CA_DIR" ]; then
    print_error "CA directory not found: $CA_DIR"
    exit 1
fi

# Check if index.txt exists
if [ ! -f "$CA_DIR/index.txt" ]; then
    print_error "Certificate database not found: $CA_DIR/index.txt"
    exit 1
fi

print_header "=========================================="
print_header "  Certificate Authority - Issued Certs"
print_header "=========================================="
echo ""

# Count certificates
TOTAL_CERTS=$(wc -l < "$CA_DIR/index.txt" | tr -d ' ')
VALID_CERTS=$(grep -c "^V" "$CA_DIR/index.txt" || true)
REVOKED_CERTS=$(grep -c "^R" "$CA_DIR/index.txt" || true)
EXPIRED_CERTS=$(grep -c "^E" "$CA_DIR/index.txt" || true)

print_info "Total certificates: $TOTAL_CERTS"
print_info "Valid certificates: $VALID_CERTS"
print_info "Revoked certificates: $REVOKED_CERTS"
print_info "Expired certificates: $EXPIRED_CERTS"
echo ""

if [ "$TOTAL_CERTS" -eq 0 ]; then
    print_info "No certificates have been issued yet."
    exit 0
fi

print_header "Certificate Details:"
print_header "===================="
echo ""

# Parse index.txt and display certificate information
while IFS=$'\t' read -r status expiry_date revocation_date serial filename subject; do
    # Determine status symbol
    case $status in
        V)
            STATUS_SYMBOL="${GREEN}✓ VALID${NC}"
            ;;
        R)
            STATUS_SYMBOL="${RED}✗ REVOKED${NC}"
            ;;
        E)
            STATUS_SYMBOL="${YELLOW}⚠ EXPIRED${NC}"
            ;;
        *)
            STATUS_SYMBOL="${YELLOW}? UNKNOWN${NC}"
            ;;
    esac
    
    # Extract CN from subject
    CN=$(echo "$subject" | sed 's/.*CN=\([^/]*\).*/\1/')
    
    # Format expiry date
    EXPIRY_FORMATTED=$(echo "$expiry_date" | sed 's/\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)Z/20\1-\2-\3 \4:\5:\6/')
    
    echo -e "Status: $STATUS_SYMBOL"
    echo "  Common Name: $CN"
    echo "  Serial: $serial"
    echo "  Expires: $EXPIRY_FORMATTED"
    
    if [ "$status" = "R" ] && [ -n "$revocation_date" ]; then
        REVOKE_FORMATTED=$(echo "$revocation_date" | sed 's/\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)Z/20\1-\2-\3 \4:\5:\6/')
        echo "  Revoked: $REVOKE_FORMATTED"
    fi
    
    # Check if certificate file exists
    CERT_FILE="$CA_DIR/certs/$CN.cert.pem"
    if [ -f "$CERT_FILE" ]; then
        echo "  Certificate: $CERT_FILE"
        
        # Get SANs if available
        SANS=$(openssl x509 -noout -text -in "$CERT_FILE" 2>/dev/null | grep -A 1 "Subject Alternative Name" | tail -n 1 | sed 's/^[[:space:]]*//' || echo "")
        if [ -n "$SANS" ]; then
            echo "  SANs: $SANS"
        fi
    fi
    
    echo ""
done < "$CA_DIR/index.txt"

print_header "=========================================="

# Check for certificates expiring soon (within 30 days)
print_info "Checking for certificates expiring soon..."
CURRENT_DATE=$(date +%s)
THIRTY_DAYS=$((30 * 24 * 60 * 60))

EXPIRING_SOON=0
while IFS=$'\t' read -r status expiry_date revocation_date serial filename subject; do
    if [ "$status" = "V" ]; then
        # Convert expiry date to epoch
        EXPIRY_EPOCH=$(date -j -f "%y%m%d%H%M%SZ" "$expiry_date" +%s 2>/dev/null || date -d "${expiry_date:0:8} ${expiry_date:8:6}" +%s 2>/dev/null || echo "0")
        
        if [ "$EXPIRY_EPOCH" -gt 0 ]; then
            DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $CURRENT_DATE) / 86400 ))
            
            if [ "$DAYS_UNTIL_EXPIRY" -le 30 ] && [ "$DAYS_UNTIL_EXPIRY" -ge 0 ]; then
                CN=$(echo "$subject" | sed 's/.*CN=\([^/]*\).*/\1/')
                print_warning "Certificate for $CN expires in $DAYS_UNTIL_EXPIRY days!"
                EXPIRING_SOON=$((EXPIRING_SOON + 1))
            fi
        fi
    fi
done < "$CA_DIR/index.txt"

if [ "$EXPIRING_SOON" -eq 0 ]; then
    print_info "No certificates expiring within 30 days."
fi

echo ""
print_info "Certificate listing complete."

# Made with Bob
