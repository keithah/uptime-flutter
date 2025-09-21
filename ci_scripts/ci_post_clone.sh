#!/bin/sh

# Xcode Cloud CI Script
# This script runs after the repository is cloned

set -e

echo "🚀 Starting Xcode Cloud post-clone setup for Flutter..."

# Check if running on Xcode Cloud
if [ -n "$CI_WORKSPACE" ]; then
    echo "✅ Running on Xcode Cloud"
else
    echo "ℹ️ Running locally"
fi

# Install Flutter
echo "📱 Installing Flutter..."
cd $CI_WORKSPACE || cd .

# Download and install Flutter
FLUTTER_VERSION="3.24.5"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_${FLUTTER_VERSION}-stable.zip"

echo "Downloading Flutter ${FLUTTER_VERSION}..."
curl -o flutter.zip $FLUTTER_URL

echo "Extracting Flutter..."
unzip -q flutter.zip

# Add Flutter to PATH
export PATH="$PWD/flutter/bin:$PATH"

# Verify Flutter installation
echo "🔍 Verifying Flutter installation..."
flutter --version

# Accept licenses
echo "✅ Accepting Flutter licenses..."
yes "y" | flutter doctor --android-licenses || true

# Run Flutter doctor
echo "🩺 Running Flutter doctor..."
flutter doctor -v

# Navigate to project directory
echo "📁 Navigating to project directory..."
if [ -n "$CI_WORKSPACE" ]; then
    cd $CI_WORKSPACE
fi

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Generate code (if needed)
echo "🔨 Generating code..."
dart run build_runner build --delete-conflicting-outputs || echo "No code generation needed"

# Analyze code
echo "🔍 Analyzing Flutter code..."
flutter analyze

# Run tests
echo "🧪 Running Flutter tests..."
flutter test

# Pre-build for macOS
echo "🏗️ Pre-building Flutter for macOS..."
flutter precache --macos

echo "✅ Xcode Cloud post-clone setup completed successfully!"