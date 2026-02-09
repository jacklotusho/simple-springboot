
#!/bin/bash

# Script to renew a certificate
# Usage: ./renew-cert.sh <domain> [additional_domains...]

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

OLD_CERT_FILE="$CA_DIR/certs/$DOMAIN.cert.pem"
OLD_KEY_FILE="$CA_DIR/private/$DOMAIN.key.pem"

# Check if CA directory exists
if [ ! -d "$CA_DIR" ]; then
    print_error "CA directory not found: $CA_DIR"
    exit 1
fi

# Check if old certificate exists
if [ ! -f "$OLD_CERT_FILE" ]; then
    print_error "Certificate not found: $OLD_CERT_FILE"
    print_info "Use create-server-cert.sh to create a new certificate"
    exit 1
fi

# Display old certificate information
print_info "Current certificate information:"
openssl x509 -noout -subject -dates -in "$OLD_CERT_FILE"
echo ""

# Check if certificate is expired or expiring soon
EXPIRY_DATE=$(openssl x509 -noout -enddate -in "$OLD_CERT_FILE" | cut -d= -f2)
EXPIRY_EPOCH=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$EXPIRY_DATE" +%s 2>/dev/null || date -d "$EXPIRY_DATE" +%s 2>/dev/null)
CURRENT_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

if [ "$DAYS_UNTIL_EXPIRY" -gt 30 ]; then
    print_warning "Certificate is still valid for $DAYS_UNTIL_EXPIRY days."
    print_warning "Are you sure you want to renew it now? (yes/no)"
    read -r CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        print_info "Renewal cancelled."
        exit 0
    fi
elif [ "$DAYS_UNTIL_EXPIRY" -lt 0 ]; then
    print_warning "Certificate has expired $((DAYS_UNTIL_EXPIRY * -1)) days ago."
else
    print_info "Certificate expires in $DAYS_UNTIL_EXPIRY days. Proceeding with renewal."
fi

# Backup old certificate
BACKUP_DIR="$CA_DIR/certs/backup"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp "$OLD_CERT_FILE" "$BACKUP_DIR/$DOMAIN.cert.pem.$TIMESTAMP"
print_info "Old certificate backed up to: $BACKUP_DIR/$DOMAIN.cert.pem.$TIMESTAMP"

# Check if private key exists
if [ ! -f "$OLD_KEY_FILE" ]; then
    print_warning "Private key not found: $OLD_KEY_FILE"
    print_info "Generating new private key..."
    openssl genrsa -out "$OLD_KEY_FILE" 2048
    chmod 400 "$OLD_KEY_FILE"
else
    print_info "Reusing existing private key: $OLD_KEY_FILE"
fi

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

# Create new CSR
print_info "Creating new certificate signing request..."
openssl req -config "$CA_DIR/openssl.cnf" \
    -key "$OLD_KEY_FILE" \
    -new -sha256 -out "$CA_DIR/csr/$DOMAIN.csr.pem" \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"

# Sign new certificate
print_info "Signing new certificate..."
openssl ca -config "$CA_DIR/openssl.cnf" \
    -extensions server_cert -days $CERT_VALIDITY_DAYS -notext -md sha256 \
    -in "$CA_DIR/csr/$DOMAIN.csr.pem" \
    -out "$OLD_CERT_FILE" \
    -batch

chmod 444 "$OLD_CERT_FILE"

# Restore original openssl.cnf
mv "$CA_DIR/openssl.cnf.bak" "$CA_DIR/openssl.cnf"
rm -f "$CA_DIR/openssl.cnf.tmp"

# Verify new certificate
print_info "Verifying new certificate..."
if openssl verify -CAfile "$CA_DIR/certs/ca-chain.cert.pem" "$OLD_CERT_FILE" > /dev/null 2>&1; then
    print_info "Certificate verification successful!"
else
    print_error "Certificate verification failed!"
    print_error "Restoring backup certificate..."
    cp "$BACKUP_DIR/$DOMAIN.cert.pem.$TIMESTAMP" "$OLD_CERT_FILE"
    exit 1
fi

# Display new certificate information
print_info "Certificate renewed successfully!"
echo ""
echo "New certificate details:"
openssl x509 -noout -subject -dates -in "$OLD_CERT_FILE"
openssl x509 -noout -text -in "$OLD_CERT_FILE" | grep -A 10 "X509v3 Subject Alternative Name:"
echo ""
print_warning "Remember to:"
echo "  1. Reload your web server configuration"
echo "  2. Test the new certificate"
echo "  3. Monitor for any issues"
