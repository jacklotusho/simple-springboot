#!/bin/bash

# Script to create and sign a server certificate
# Usage: ./create-server-cert.sh <domain> [additional_domains...]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CA_DIR="../ca/intermediate-ca"
CERT_VALIDITY_DAYS=375

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
if [ $# -lt 1 ]; then
    print_error "Usage: $0 <domain> [additional_domains...]"
    echo "Example: $0 example.com www.example.com api.example.com"
    exit 1
fi

DOMAIN=$1
shift
ADDITIONAL_DOMAINS=("$@")

# Check if CA directory exists
if [ ! -d "$CA_DIR" ]; then
    print_error "CA directory not found: $CA_DIR"
    print_info "Please set up your CA first using the CA-SETUP.md guide"
    exit 1
fi

# Check if openssl.cnf exists
if [ ! -f "$CA_DIR/openssl.cnf" ]; then
    print_error "OpenSSL configuration not found: $CA_DIR/openssl.cnf"
    exit 1
fi

print_info "Creating certificate for domain: $DOMAIN"

# Create temporary alt_names file
ALT_NAMES_FILE=$(mktemp)
echo "[ alt_names ]" > "$ALT_NAMES_FILE"
echo "DNS.1 = $DOMAIN" >> "$ALT_NAMES_FILE"

# Add additional domains
COUNTER=2
for alt_domain in "${ADDITIONAL_DOMAINS[@]}"; do
    echo "DNS.$COUNTER = $alt_domain" >> "$ALT_NAMES_FILE"
    print_info "Adding alternative name: $alt_domain"
    ((COUNTER++))
done

# Backup original openssl.cnf
cp "$CA_DIR/openssl.cnf" "$CA_DIR/openssl.cnf.bak"

# Update openssl.cnf with new alt_names
sed -i.tmp '/\[ alt_names \]/,/^$/d' "$CA_DIR/openssl.cnf"
cat "$ALT_NAMES_FILE" >> "$CA_DIR/openssl.cnf"
rm "$ALT_NAMES_FILE"

# Generate private key
print_info "Generating private key..."
openssl genrsa -out "$CA_DIR/private/$DOMAIN.key.pem" 2048
chmod 400 "$CA_DIR/private/$DOMAIN.key.pem"

# Create CSR
print_info "Creating certificate signing request..."
openssl req -config "$CA_DIR/openssl.cnf" \
    -key "$CA_DIR/private/$DOMAIN.key.pem" \
    -new -sha256 -out "$CA_DIR/csr/$DOMAIN.csr.pem" \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"

# Sign certificate
print_info "Signing certificate..."
openssl ca -config "$CA_DIR/openssl.cnf" \
    -extensions server_cert -days $CERT_VALIDITY_DAYS -notext -md sha256 \
    -in "$CA_DIR/csr/$DOMAIN.csr.pem" \
    -out "$CA_DIR/certs/$DOMAIN.cert.pem" \
    -batch

chmod 444 "$CA_DIR/certs/$DOMAIN.cert.pem"

# Restore original openssl.cnf
mv "$CA_DIR/openssl.cnf.bak" "$CA_DIR/openssl.cnf"
rm -f "$CA_DIR/openssl.cnf.tmp"

# Verify certificate
print_info "Verifying certificate..."
if openssl verify -CAfile "$CA_DIR/certs/ca-chain.cert.pem" "$CA_DIR/certs/$DOMAIN.cert.pem" > /dev/null 2>&1; then
    print_info "Certificate verification successful!"
else
    print_error "Certificate verification failed!"
    exit 1
fi

# Display certificate information
print_info "Certificate created successfully!"
echo ""
echo "Certificate files:"
echo "  Private Key: $CA_DIR/private/$DOMAIN.key.pem"
echo "  Certificate: $CA_DIR/certs/$DOMAIN.cert.pem"
echo "  CA Chain:    $CA_DIR/certs/ca-chain.cert.pem"
echo ""
echo "Certificate details:"
openssl x509 -noout -text -in "$CA_DIR/certs/$DOMAIN.cert.pem" | grep -A 2 "Subject:"
openssl x509 -noout -text -in "$CA_DIR/certs/$DOMAIN.cert.pem" | grep -A 10 "X509v3 Subject Alternative Name:"
openssl x509 -noout -dates -in "$CA_DIR/certs/$DOMAIN.cert.pem"

print_info "Certificate created and signed successfully!"

# Made with Bob
