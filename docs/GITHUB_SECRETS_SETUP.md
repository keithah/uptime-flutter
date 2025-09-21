# GitHub Secrets Setup for macOS Code Signing

## Required Secrets

Configure these secrets in your GitHub repository settings under Settings → Secrets and variables → Actions:

### 1. DEVELOPER_CERTIFICATE_BASE64
The base64-encoded Developer ID Application certificate (.p12 file).

To create this secret:
```bash
# Convert your .p12 certificate to base64
base64 -i /path/to/developer_id_application.p12 | pbcopy
```

### 2. DEVELOPER_P12_PASSWORD
The password for your .p12 certificate file.

### 3. DEVELOPER_SIGNING_IDENTITY
The full name of your Developer ID certificate.

To find this:
```bash
security find-identity -v -p codesigning
# Look for "Developer ID Application: Your Name (TEAMID)"
# Use the full string including quotes
```

Example: `"Developer ID Application: Keith Herrington (6R7S5GA944)"`

### 4. KEYCHAIN_PASSWORD
A secure password for the temporary keychain created during CI/CD.
Generate a strong random password for this.

### 5. TEAM_ID
Your Apple Developer Team ID (e.g., `6R7S5GA944`).

### 6. APP_BUNDLE_ID
Your app's bundle identifier (e.g., `com.yourcompany.uptime-flutter`).

### 7. NOTARIZE_USERNAME
Your Apple ID email used for notarization.

### 8. NOTARIZE_PASSWORD
An app-specific password for notarization.
Create one at: https://appleid.apple.com/account/manage
Under "Security" → "App-Specific Passwords"

## Verification

After setting up all secrets, the workflow will:
1. Import the certificate into a temporary keychain
2. Sign the app with Developer ID
3. Create a signed DMG
4. Notarize the DMG with Apple
5. Verify all signatures

## Troubleshooting

If you see "The specified item could not be found in the keychain" errors:
- Ensure DEVELOPER_CERTIFICATE_BASE64 is properly encoded
- Verify DEVELOPER_P12_PASSWORD is correct
- Check that DEVELOPER_SIGNING_IDENTITY matches exactly what's in the certificate