#!/bin/bash
# Creates a local self-signed code-signing certificate ("Tagara Dev") in the login keychain.
# Signing every build with the same identity lets macOS remember Microphone/Accessibility grants.
set -euo pipefail
NAME="Tagara Dev"
if security find-certificate -c "$NAME" >/dev/null 2>&1; then
    echo "Certificado '$NAME' já existe."
    exit 0
fi
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/cert.cnf" <<CNF
[req]
distinguished_name = dn
prompt = no
[dn]
CN = $NAME
[ext]
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
basicConstraints = critical, CA:false
CNF
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -config "$TMP/cert.cnf" -extensions ext 2>/dev/null
openssl pkcs12 -export -legacy -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -out "$TMP/cert.p12" -passout pass:tagara 2>/dev/null \
  || openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" -out "$TMP/cert.p12" -passout pass:tagara
security import "$TMP/cert.p12" -k ~/Library/Keychains/login.keychain-db -P tagara -T /usr/bin/codesign
echo "Certificado '$NAME' criado."
