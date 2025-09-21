#!/bin/bash

# Script to export the working Developer ID certificate from keychain
# This will get the certificate that's currently working in your local keychain

echo "Exporting working Developer ID certificate..."

CERT_NAME="Developer ID Application: Keith Herrington (6R7S5GA944)"
OUTPUT_FILE="/tmp/working_developer_id.p12"

echo "Certificate to export: $CERT_NAME"

# Export the certificate with private key
# You'll be prompted for:
# 1. Your keychain password (to access the certificate)
# 2. A password for the new p12 file (can be empty or set a new one)

if security export -k login.keychain-db -t identities -f pkcs12 -o "$OUTPUT_FILE" "$CERT_NAME"; then
    echo ""
    echo "✅ Certificate exported successfully to: $OUTPUT_FILE"
    echo ""
    echo "File size: $(stat -f%z "$OUTPUT_FILE") bytes"
    echo ""
    echo "To use in GitHub Actions:"
    echo "1. Convert to base64:"
    echo "   base64 -i $OUTPUT_FILE | pbcopy"
    echo ""
    echo "2. Update GitHub secret DEVELOPER_CERTIFICATE_BASE64 with the clipboard content"
    echo ""
    echo "3. Update DEVELOPER_P12_PASSWORD with the password you just set"
    echo "   (or leave empty if you didn't set a password)"
    echo ""
    echo "4. The DEVELOPER_SIGNING_IDENTITY should be:"
    echo "   \"$CERT_NAME\""
else
    echo "❌ Export failed. Make sure the certificate is in your keychain."
fi