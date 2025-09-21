#!/bin/sh

# Xcode Cloud Pre-Build Script
# This script runs before Xcode starts building

set -e

echo "🏗️ Starting Xcode Cloud pre-build setup..."

# Ensure we're in the right directory
if [ -n "$CI_WORKSPACE" ]; then
    cd $CI_WORKSPACE
fi

# Set Flutter path
export PATH="$PWD/flutter/bin:$PATH"

echo "🔍 Verifying Flutter is available..."
which flutter
flutter --version

echo "🏗️ Building Flutter for macOS release..."
flutter build macos --release

echo "✅ Pre-build setup completed successfully!"