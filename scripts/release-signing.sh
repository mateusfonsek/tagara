#!/bin/bash
# Creates the self-signed "Tagara Release" code-signing certificate and stores it in the repo's
# GitHub secrets (SIGNING_CERT_P12, SIGNING_CERT_PASSWORD), where the release workflow signs with it.
#
# macOS ties Microphone and Accessibility grants to the app's signing identity. Ad-hoc signing
# changes it on every build, so every update lost the grants; one stable certificate keeps them.
#
# Run once. Rotating the certificate makes every user grant the permissions again, so keep the
# backup this script leaves in ~/.config/tagara/ (GitHub secrets can't be read back).
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="Tagara Release"
BACKUP="$HOME/.config/tagara/release-signing.p12"
if [ -e "$BACKUP" ]; then
    echo "Já existe $BACKUP. Apague antes se quiser mesmo trocar o certificado." >&2
    exit 1
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
PASSWORD=$(openssl rand -hex 24)
openssl req -x509 -newkey rsa:2048 -nodes -days 7300 \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -config "$TMP/cert.cnf" -extensions ext 2>/dev/null
openssl pkcs12 -export -legacy -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -out "$TMP/cert.p12" -passout "pass:$PASSWORD" 2>/dev/null \
  || openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" -out "$TMP/cert.p12" -passout "pass:$PASSWORD"

base64 -i "$TMP/cert.p12" | gh secret set SIGNING_CERT_P12
printf '%s' "$PASSWORD" | gh secret set SIGNING_CERT_PASSWORD

mkdir -p "$(dirname "$BACKUP")"
cp "$TMP/cert.p12" "$BACKUP"
printf '%s\n' "$PASSWORD" > "$BACKUP.password"
chmod 600 "$BACKUP" "$BACKUP.password"
echo "Certificado '$NAME' nos segredos do GitHub. Cópia de segurança em $BACKUP."
