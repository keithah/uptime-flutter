#!/bin/bash

# Test certificate import script to verify it works locally before GHA

set -e

CERT_FILE="/Users/keith/Library/Mobile Documents/com~apple~CloudDocs/xcode dev certs/developer_id_application_try_again.p12"
TEST_KEYCHAIN="/tmp/test-import.keychain-db"
KEYCHAIN_PASSWORD="testpass123"
CERTIFICATE_PATH="/tmp/test_dev_cert.p12"

echo "🧪 Testing certificate import script locally..."

# Clean up any existing test keychain
security delete-keychain "$TEST_KEYCHAIN" 2>/dev/null || true
rm -f "$CERTIFICATE_PATH"

# Copy certificate to test location
cp "$CERT_FILE" "$CERTIFICATE_PATH"
echo "Certificate file size: $(stat -f%z "$CERTIFICATE_PATH") bytes"

# Create test keychain (same as workflow)
echo "Creating test keychain..."
security create-keychain -p "$KEYCHAIN_PASSWORD" "$TEST_KEYCHAIN"
security set-keychain-settings -lut 21600 "$TEST_KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$TEST_KEYCHAIN"

echo ""
echo "Testing import methods..."

# Set up non-interactive environment
export SHELL=/bin/bash

# Method 1: Use empty passphrase explicitly
echo "Method 1: Empty passphrase with -P..."
if echo "" | security import "$CERTIFICATE_PATH" -k "$TEST_KEYCHAIN" -P "" -A -t cert -f pkcs12 -T /usr/bin/codesign -T /usr/bin/security 2>/dev/null; then
  echo "✅ Method 1 succeeded"
  METHOD_USED="Method 1: Empty passphrase"
# Method 2: Try without -P flag
elif echo "" | security import "$CERTIFICATE_PATH" -k "$TEST_KEYCHAIN" -A -t cert -f pkcs12 -T /usr/bin/codesign -T /usr/bin/security 2>/dev/null; then
  echo "✅ Method 2 succeeded"
  METHOD_USED="Method 2: No -P flag"
# Method 3: Use expect to handle password prompt
elif command -v expect >/dev/null 2>&1; then
  echo "Method 3: Using expect..."
  if expect -c "
    spawn security import \"$CERTIFICATE_PATH\" -k \"$TEST_KEYCHAIN\" -A -t cert -f pkcs12 -T /usr/bin/codesign -T /usr/bin/security
    expect {
      \"password to unlock*\" { send \"\r\"; exp_continue }
      eof
    }
  " 2>/dev/null; then
    echo "✅ Method 3 succeeded"
    METHOD_USED="Method 3: Expect automation"
  else
    echo "❌ Method 3 failed"
    METHOD_USED="FAILED"
  fi
else
  echo "❌ All methods failed"
  METHOD_USED="FAILED"
fi

if [ "$METHOD_USED" != "FAILED" ]; then
  echo ""
  echo "✅ Certificate import successful using: $METHOD_USED"

  # Test post-import steps
  echo ""
  echo "Testing post-import steps..."

  # Unlock keychain again after import
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$TEST_KEYCHAIN"

  # Set default keychain first
  security default-keychain -s "$TEST_KEYCHAIN"

  # Add keychain to search list
  security list-keychain -d user -s "$TEST_KEYCHAIN" login.keychain

  # Set key partition list
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$TEST_KEYCHAIN"

  # Wait for sync
  sleep 1

  # Check what was imported
  echo ""
  echo "Checking imported items..."
  echo "Certificates:"
  security find-certificate -a "$TEST_KEYCHAIN" | head -10

  echo ""
  echo "Private keys:"
  security find-key -a "$TEST_KEYCHAIN" | head -5

  echo ""
  echo "Code signing identities:"
  if security find-identity -v -p codesigning "$TEST_KEYCHAIN" | grep -q "Developer ID Application"; then
    echo "✅ Developer ID certificate found!"
    security find-identity -v -p codesigning "$TEST_KEYCHAIN"
  else
    echo "⚠️  No Developer ID certificate found in codesigning identities"
    echo "All identities:"
    security find-identity -v -p codesigning "$TEST_KEYCHAIN"
  fi

  echo ""
  echo "🎉 Test completed successfully!"
else
  echo ""
  echo "❌ Test failed - certificate import unsuccessful"
fi

# Clean up
echo ""
echo "Cleaning up test files..."
security delete-keychain "$TEST_KEYCHAIN" 2>/dev/null || true
rm -f "$CERTIFICATE_PATH"

echo "✅ Test cleanup complete"