#!/bin/bash

# Script to revoke a certificate
# Usage: ./revoke-cert.sh <domain>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if domain is provided
if [ $# -ne 1 ]; then
    print_error "Usage: $0 <domain>"
    echo "Example: $0 example.com"
    exit 1
fi

DOMAIN=$1
CERT_FILE="$CA_DIR/certs/$DOMAIN.cert.pem"

# Check if CA directory exists
if [ ! -d "$CA_DIR" ]; then
    print_error "CA directory not found: $CA_DIR"
    exit 1
fi

# Check if certificate exists
if [ ! -f "$CERT_FILE" ]; then
    print_error "Certificate not found: $CERT_FILE"
    exit 1
fi

# Display certificate information
print_info "Certificate to be revoked:"
openssl x509 -noout -subject -dates -in "$CERT_FILE"
echo ""

# Confirm revocation
print_warning "Are you sure you want to revoke this certificate? (yes/no)"
read -r CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Revocation cancelled."
    exit 0
fi

# Revoke certificate
print_info "Revoking certificate..."
openssl ca -config "$CA_DIR/openssl.cnf" -revoke "$CERT_FILE"

# Generate new CRL
print_info "Generating new Certificate Revocation List (CRL)..."
openssl ca -config "$CA_DIR/openssl.cnf" -gencrl -out "$CA_DIR/crl/intermediate.crl.pem"

print_info "Certificate revoked successfully!"
print_info "CRL updated: $CA_DIR/crl/intermediate.crl.pem"
echo ""
print_warning "Remember to:"
echo "  1. Publish the updated CRL to your web server"
echo "  2. Remove the certificate from your web server configuration"
echo "  3. Notify affected parties about the revocation"

# Made with Bob
