# Setting Up Your Own Certificate Authority (CA)

This guide explains how to set up your own Certificate Authority similar to Let's Encrypt for issuing SSL/TLS certificates.

## Overview

A Certificate Authority (CA) is an entity that issues digital certificates. This guide covers:
1. Creating a Root CA
2. Creating an Intermediate CA (recommended for security)
3. Issuing server certificates
4. Automating certificate management

## Prerequisites

- OpenSSL installed (`openssl version`)
- Linux/macOS environment (or WSL on Windows)
- Basic understanding of PKI (Public Key Infrastructure)

## Directory Structure

```
ca/
├── root-ca/
│   ├── private/          # Root CA private key (keep secure!)
│   ├── certs/            # Root CA certificate
│   ├── newcerts/         # Issued certificates
│   ├── crl/              # Certificate Revocation Lists
│   └── index.txt         # Certificate database
├── intermediate-ca/
│   ├── private/          # Intermediate CA private key
│   ├── certs/            # Intermediate CA certificate
│   ├── csr/              # Certificate signing requests
│   ├── newcerts/         # Issued certificates
│   └── index.txt         # Certificate database
└── scripts/              # Automation scripts
```

## Step 1: Create Root CA

### 1.1 Create Directory Structure

```bash
mkdir -p ca/root-ca/{private,certs,newcerts,crl}
cd ca/root-ca
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber
```

### 1.2 Create Root CA Configuration

Create `root-ca/openssl.cnf`:

```ini
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = .
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

private_key       = $dir/private/ca.key.pem
certificate       = $dir/certs/ca.cert.pem

crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 3650
preserve          = no
policy            = policy_strict

[ policy_strict ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

countryName_default             = US
stateOrProvinceName_default     = State
localityName_default            = City
0.organizationName_default      = My Organization
organizationalUnitName_default  = My Organization CA
emailAddress_default            = ca@example.com

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
authorityKeyIdentifier=keyid:always

[ ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
```

### 1.3 Generate Root CA Private Key

```bash
# Generate 4096-bit RSA key with AES-256 encryption
openssl genrsa -aes256 -out private/ca.key.pem 4096
chmod 400 private/ca.key.pem
```

**Important**: Store this password securely! You'll need it for all CA operations.

### 1.4 Create Root CA Certificate

```bash
openssl req -config openssl.cnf \
  -key private/ca.key.pem \
  -new -x509 -days 7300 -sha256 -extensions v3_ca \
  -out certs/ca.cert.pem

# Verify the certificate
openssl x509 -noout -text -in certs/ca.cert.pem
```

## Step 2: Create Intermediate CA

### 2.1 Create Directory Structure

```bash
cd ..
mkdir -p intermediate-ca/{private,certs,csr,newcerts,crl}
cd intermediate-ca
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber
```

### 2.2 Create Intermediate CA Configuration

Create `intermediate-ca/openssl.cnf` (similar to root CA but with different paths):

```ini
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = .
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

private_key       = $dir/private/intermediate.key.pem
certificate       = $dir/certs/intermediate.cert.pem

crlnumber         = $dir/crlnumber
crl               = $dir/crl/intermediate.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_loose

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
# DNS.1 = example.com
# DNS.2 = www.example.com
# IP.1 = 192.168.1.1

[ crl_ext ]
authorityKeyIdentifier=keyid:always
```

### 2.3 Generate Intermediate CA Private Key

```bash
openssl genrsa -aes256 -out private/intermediate.key.pem 4096
chmod 400 private/intermediate.key.pem
```

### 2.4 Create Intermediate CA Certificate Signing Request (CSR)

```bash
openssl req -config openssl.cnf -new -sha256 \
  -key private/intermediate.key.pem \
  -out csr/intermediate.csr.pem
```

### 2.5 Sign Intermediate CA Certificate with Root CA

```bash
cd ../root-ca
openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
  -days 3650 -notext -md sha256 \
  -in ../intermediate-ca/csr/intermediate.csr.pem \
  -out ../intermediate-ca/certs/intermediate.cert.pem

chmod 444 ../intermediate-ca/certs/intermediate.cert.pem

# Verify the intermediate certificate
openssl x509 -noout -text -in ../intermediate-ca/certs/intermediate.cert.pem
openssl verify -CAfile certs/ca.cert.pem ../intermediate-ca/certs/intermediate.cert.pem
```

### 2.6 Create Certificate Chain

```bash
cd ../intermediate-ca
cat certs/intermediate.cert.pem ../root-ca/certs/ca.cert.pem > certs/ca-chain.cert.pem
chmod 444 certs/ca-chain.cert.pem
```

## Step 3: Issue Server Certificates

### 3.1 Generate Server Private Key

```bash
cd intermediate-ca
openssl genrsa -out private/example.com.key.pem 2048
chmod 400 private/example.com.key.pem
```

### 3.2 Create Server Certificate Signing Request

```bash
openssl req -config openssl.cnf \
  -key private/example.com.key.pem \
  -new -sha256 -out csr/example.com.csr.pem
```

### 3.3 Sign Server Certificate

First, update the `[alt_names]` section in `openssl.cnf`:

```ini
[ alt_names ]
DNS.1 = example.com
DNS.2 = www.example.com
DNS.3 = *.example.com
```

Then sign the certificate:

```bash
openssl ca -config openssl.cnf \
  -extensions server_cert -days 375 -notext -md sha256 \
  -in csr/example.com.csr.pem \
  -out certs/example.com.cert.pem

chmod 444 certs/example.com.cert.pem

# Verify the certificate
openssl x509 -noout -text -in certs/example.com.cert.pem
openssl verify -CAfile certs/ca-chain.cert.pem certs/example.com.cert.pem
```

## Step 4: Deploy Certificates

### 4.1 For Web Servers (Apache/Nginx)

**Nginx Configuration:**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    ssl_certificate /path/to/ca/intermediate-ca/certs/example.com.cert.pem;
    ssl_certificate_key /path/to/ca/intermediate-ca/private/example.com.key.pem;
    ssl_trusted_certificate /path/to/ca/intermediate-ca/certs/ca-chain.cert.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # ... rest of configuration
}
```

**Apache Configuration:**

```apache
<VirtualHost *:443>
    ServerName example.com
    ServerAlias www.example.com

    SSLEngine on
    SSLCertificateFile /path/to/ca/intermediate-ca/certs/example.com.cert.pem
    SSLCertificateKeyFile /path/to/ca/intermediate-ca/private/example.com.key.pem
    SSLCertificateChainFile /path/to/ca/intermediate-ca/certs/ca-chain.cert.pem

    # ... rest of configuration
</VirtualHost>
```

### 4.2 Install Root CA Certificate on Client Systems

**Linux:**
```bash
sudo cp root-ca/certs/ca.cert.pem /usr/local/share/ca-certificates/my-ca.crt
sudo update-ca-certificates
```

**macOS:**
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain root-ca/certs/ca.cert.pem
```

**Windows:**
```powershell
# Import to Trusted Root Certification Authorities
certutil -addstore -f "ROOT" ca.cert.pem
```

**Browser (Firefox):**
1. Settings → Privacy & Security → Certificates → View Certificates
2. Authorities → Import → Select `ca.cert.pem`
3. Trust for identifying websites

## Step 5: Certificate Revocation

### 5.1 Revoke a Certificate

```bash
cd intermediate-ca
openssl ca -config openssl.cnf -revoke certs/example.com.cert.pem
```

### 5.2 Generate Certificate Revocation List (CRL)

```bash
openssl ca -config openssl.cnf -gencrl -out crl/intermediate.crl.pem
```

### 5.3 Publish CRL

Make the CRL available via HTTP:

```nginx
location /crl {
    alias /path/to/ca/intermediate-ca/crl;
    autoindex on;
}
```

## Automation Scripts

See the `scripts/` directory for automation tools:

- `create-server-cert.sh` - Automated server certificate generation
- `renew-cert.sh` - Certificate renewal
- `revoke-cert.sh` - Certificate revocation
- `list-certs.sh` - List all issued certificates

## Security Best Practices

1. **Protect Private Keys**
   - Store root CA private key offline (air-gapped system)
   - Use strong passwords (20+ characters)
   - Encrypt backups

2. **Key Rotation**
   - Rotate intermediate CA every 3-5 years
   - Issue server certificates with short validity (90 days recommended)

3. **Access Control**
   - Limit access to CA systems
   - Use hardware security modules (HSM) for production
   - Implement audit logging

4. **Monitoring**
   - Monitor certificate expiration
   - Track certificate issuance
   - Alert on suspicious activity

5. **Backup**
   - Regular encrypted backups of CA data
   - Store backups in multiple secure locations
   - Test restoration procedures

## Comparison with Let's Encrypt

| Feature | Your CA | Let's Encrypt |
|---------|---------|---------------|
| Cost | Free | Free |
| Automation | Manual/Custom | ACME Protocol |
| Trust | Manual installation | Publicly trusted |
| Validity | Configurable | 90 days |
| Use Case | Internal/Private | Public websites |
| Revocation | Manual CRL | OCSP |

## ACME Protocol (Optional)

To make your CA work like Let's Encrypt with automatic certificate management, consider implementing:

1. **Step-CA** - Open source CA with ACME support
   ```bash
   # Install step-ca
   wget https://dl.step.sm/gh-release/cli/docs-ca-install/v0.24.4/step-ca_linux_0.24.4_amd64.tar.gz
   tar -xf step-ca_linux_0.24.4_amd64.tar.gz
   sudo cp step-ca_0.24.4/bin/step-ca /usr/local/bin/
   
   # Initialize CA
   step ca init
   ```

2. **Certbot Integration**
   ```bash
   certbot certonly --server https://your-ca.example.com/acme/acme/directory \
     --domain example.com
   ```

## Troubleshooting

### Common Issues

1. **"unable to get local issuer certificate"**
   - Ensure ca-chain.cert.pem includes both intermediate and root certificates
   - Verify certificate order (server → intermediate → root)

2. **"certificate has expired"**
   - Check certificate validity: `openssl x509 -noout -dates -in cert.pem`
   - Renew certificate before expiration

3. **Browser shows "Not Secure"**
   - Root CA not installed in browser/system trust store
   - Certificate doesn't include required SAN (Subject Alternative Name)

4. **"serial number already exists"**
   - Increment serial number in `serial` file
   - Or use: `echo $(($(cat serial) + 1)) > serial`

## Resources

- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [RFC 5280 - X.509 Certificate](https://tools.ietf.org/html/rfc5280)
- [Let's Encrypt - How It Works](https://letsencrypt.org/how-it-works/)
- [Step-CA Documentation](https://smallstep.com/docs/step-ca)

## License

This documentation is provided for educational purposes.