# CA Management Scripts

This directory contains automation scripts for managing your Certificate Authority (CA).

## Available Scripts

### 1. create-server-cert.sh
Creates and signs a new server certificate.

**Usage:**
```bash
./create-server-cert.sh <domain> [additional_domains...]
```

**Example:**
```bash
./create-server-cert.sh example.com www.example.com api.example.com
```

**What it does:**
- Generates a private key for the domain
- Creates a Certificate Signing Request (CSR)
- Signs the certificate with the Intermediate CA
- Adds Subject Alternative Names (SANs) for all specified domains
- Verifies the certificate

**Output:**
- Private key: `../ca/intermediate-ca/private/<domain>.key.pem`
- Certificate: `../ca/intermediate-ca/certs/<domain>.cert.pem`
- CA chain: `../ca/intermediate-ca/certs/ca-chain.cert.pem`

---

### 2. list-certs.sh
Lists all issued certificates with their status and expiration dates.

**Usage:**
```bash
./list-certs.sh
```

**What it does:**
- Shows total, valid, revoked, and expired certificates
- Displays detailed information for each certificate
- Warns about certificates expiring within 30 days
- Shows Subject Alternative Names (SANs) for each certificate

**Output Example:**
```
==========================================
  Certificate Authority - Issued Certs
==========================================

Total certificates: 5
Valid certificates: 4
Revoked certificates: 1
Expired certificates: 0

Certificate Details:
====================

Status: ✓ VALID
  Common Name: example.com
  Serial: 1000
  Expires: 2025-03-15 10:30:45
  Certificate: ../ca/intermediate-ca/certs/example.com.cert.pem
  SANs: DNS:example.com, DNS:www.example.com
```

---

### 3. revoke-cert.sh
Revokes a certificate and updates the Certificate Revocation List (CRL).

**Usage:**
```bash
./revoke-cert.sh <domain>
```

**Example:**
```bash
./revoke-cert.sh example.com
```

**What it does:**
- Displays certificate information
- Asks for confirmation
- Revokes the certificate
- Generates updated CRL
- Provides instructions for next steps

**Important:**
After revoking a certificate, you must:
1. Publish the updated CRL to your web server
2. Remove the certificate from your web server configuration
3. Notify affected parties about the revocation

---

### 4. renew-cert.sh
Renews an existing certificate with the same or updated domains.

**Usage:**
```bash
./renew-cert.sh <domain> [additional_domains...]
```

**Example:**
```bash
./renew-cert.sh example.com www.example.com api.example.com
```

**What it does:**
- Checks current certificate expiration
- Backs up the old certificate
- Reuses the existing private key (or generates new one if missing)
- Creates a new CSR
- Signs a new certificate
- Verifies the new certificate
- Provides rollback if verification fails

**Features:**
- Warns if certificate is still valid for more than 30 days
- Automatically backs up old certificates to `backup/` directory
- Reuses existing private key for continuity
- Supports adding/removing SANs during renewal

---

## Prerequisites

Before using these scripts, ensure:

1. **CA is set up** - Follow the instructions in `../CA-SETUP.md`
2. **Directory structure exists:**
   ```
   ../ca/
   ├── root-ca/
   │   ├── private/
   │   ├── certs/
   │   └── openssl.cnf
   └── intermediate-ca/
       ├── private/
       ├── certs/
       ├── csr/
       ├── newcerts/
       └── openssl.cnf
   ```
3. **OpenSSL is installed** - `openssl version`
4. **Scripts are executable** - `chmod +x *.sh`

## Common Workflows

### Initial Certificate Creation
```bash
# Create a certificate for a domain
./create-server-cert.sh example.com www.example.com

# List all certificates to verify
./list-certs.sh
```

### Certificate Renewal
```bash
# Check which certificates are expiring soon
./list-certs.sh

# Renew a certificate
./renew-cert.sh example.com www.example.com

# Verify the renewal
./list-certs.sh
```

### Certificate Revocation
```bash
# Revoke a compromised certificate
./revoke-cert.sh example.com

# Verify revocation
./list-certs.sh
```

### Regular Maintenance
```bash
# Weekly: Check for expiring certificates
./list-certs.sh

# Monthly: Review all certificates
./list-certs.sh > certificate-report-$(date +%Y%m).txt
```

## Security Best Practices

1. **Protect Private Keys**
   - Never share private keys
   - Keep backups encrypted
   - Use strong file permissions (400 for keys)

2. **Regular Monitoring**
   - Run `list-certs.sh` weekly
   - Set up automated alerts for expiring certificates
   - Monitor certificate usage

3. **Certificate Lifecycle**
   - Renew certificates before expiration (30 days recommended)
   - Keep validity periods short (90-375 days)
   - Revoke compromised certificates immediately

4. **Backup Strategy**
   - Regular backups of CA directory
   - Store backups securely and encrypted
   - Test restoration procedures

5. **Access Control**
   - Limit access to CA systems
   - Use separate accounts for CA operations
   - Audit all certificate operations

## Troubleshooting

### "CA directory not found"
**Solution:** Ensure the CA is set up at `../ca/` relative to the scripts directory.

### "Certificate verification failed"
**Possible causes:**
- CA chain is incomplete
- Certificate was signed by wrong CA
- OpenSSL configuration error

**Solution:** Check that `ca-chain.cert.pem` includes both intermediate and root certificates.

### "Serial number already exists"
**Solution:** This shouldn't happen with these scripts, but if it does:
```bash
cd ../ca/intermediate-ca
echo $(($(cat serial) + 1)) > serial
```

### "Permission denied"
**Solution:** Make scripts executable:
```bash
chmod +x *.sh
```

### Date parsing errors on different systems
The scripts handle both macOS and Linux date formats. If you encounter issues:
- macOS uses: `date -j -f`
- Linux uses: `date -d`

## Integration with Web Servers

### Nginx
```nginx
server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /path/to/ca/intermediate-ca/certs/example.com.cert.pem;
    ssl_certificate_key /path/to/ca/intermediate-ca/private/example.com.key.pem;
    ssl_trusted_certificate /path/to/ca/intermediate-ca/certs/ca-chain.cert.pem;
}
```

### Apache
```apache
<VirtualHost *:443>
    ServerName example.com
    
    SSLEngine on
    SSLCertificateFile /path/to/ca/intermediate-ca/certs/example.com.cert.pem
    SSLCertificateKeyFile /path/to/ca/intermediate-ca/private/example.com.key.pem
    SSLCertificateChainFile /path/to/ca/intermediate-ca/certs/ca-chain.cert.pem
</VirtualHost>
```

## Automation

### Cron Job for Certificate Monitoring
```bash
# Add to crontab: crontab -e
# Check for expiring certificates every Monday at 9 AM
0 9 * * 1 /path/to/ca-scripts/list-certs.sh | mail -s "Weekly Certificate Report" admin@example.com
```

### Auto-renewal Script
Create a wrapper script for automatic renewal:
```bash
#!/bin/bash
cd /path/to/ca-scripts
./list-certs.sh | grep "expires in" | while read line; do
    domain=$(echo $line | awk '{print $3}')
    days=$(echo $line | awk '{print $6}')
    if [ "$days" -lt 30 ]; then
        ./renew-cert.sh "$domain"
    fi
done
```

## Support

For detailed CA setup instructions, see: `../CA-SETUP.md`

For OpenSSL documentation: https://www.openssl.org/docs/

## License

These scripts are provided for educational and internal use purposes.