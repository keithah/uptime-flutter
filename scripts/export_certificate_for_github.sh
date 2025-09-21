#!/bin/bash

# Script to export Developer ID certificate for GitHub Actions
# Usage: ./export_certificate_for_github.sh [certificate-password]

echo "Exporting Developer ID certificate for GitHub Actions..."

# Path to the p12 file
P12_FILE="/Users/keith/Library/Mobile Documents/com~apple~CloudDocs/xcode dev certs/developer_id_application.p12"

if [ ! -f "$P12_FILE" ]; then
    echo "Error: Certificate file not found at $P12_FILE"
    exit 1
fi

# Convert to base64 and copy to clipboard
echo "Converting certificate to base64..."
base64 -i "$P12_FILE" | pbcopy

echo "✅ Certificate has been base64-encoded and copied to clipboard!"
echo ""
echo "Next steps:"
echo "1. Go to your GitHub repository settings"
echo "2. Navigate to Settings → Secrets and variables → Actions"
echo "3. Create/update the following secrets:"
echo ""
echo "   DEVELOPER_CERTIFICATE_BASE64: (paste from clipboard)"
echo "   DEVELOPER_P12_PASSWORD: (your certificate password)"
echo "   DEVELOPER_SIGNING_IDENTITY: \"Developer ID Application: Keith Herrington (6R7S5GA944)\""
echo "   KEYCHAIN_PASSWORD: (create a secure random password)"
echo "   TEAM_ID: 6R7S5GA944"
echo "   APP_BUNDLE_ID: (your app bundle identifier)"
echo "   NOTARIZE_USERNAME: (your Apple ID)"
echo "   NOTARIZE_PASSWORD: (app-specific password from appleid.apple.com)"
echo ""
echo "The certificate is now in your clipboard - paste it as DEVELOPER_CERTIFICATE_BASE64"