# Build and Distribution Setup

This project supports two build systems for maximum flexibility:

1. **Xcode Cloud** - For App Store distribution (recommended for releases)
2. **GitHub Actions** - For development builds and other platforms

## 🍎 Xcode Cloud Setup (App Store Distribution)

### Prerequisites
- Apple Developer Account
- App Store Connect access
- Xcode project configured with proper bundle identifier

### Configuration Steps

1. **Set up your app in App Store Connect:**
   - Create a new app with your chosen bundle identifier
   - Configure app metadata, pricing, etc.

2. **Configure Xcode Cloud:**
   - Open your project in Xcode
   - Go to Product → Xcode Cloud → Create Workflow
   - Connect your repository
   - Choose "Archive - iOS" workflow (we'll customize for macOS)

3. **Required Xcode Cloud Environment Variables:**
   ```
   FLUTTER_VERSION=3.24.5
   ```

4. **Xcode Cloud Workflow Configuration:**
   - Archive Action: macOS
   - Scheme: Runner (macOS)
   - Configuration: Release
   - Post-Actions: Distribute to App Store Connect

### Custom Scripts
The project includes Xcode Cloud scripts:
- `ci_scripts/ci_post_clone.sh` - Installs Flutter and dependencies
- `ci_scripts/ci_pre_xcodebuild.sh` - Builds Flutter for macOS

### App Store Entitlements
The project is configured with proper App Store sandboxing:
- Network client access (for Uptime Kuma connections)
- User notifications (for monitor alerts)
- User-selected file access (for settings import/export)
- No unnecessary permissions

## 🤖 GitHub Actions Setup (Development & Multi-Platform)

### Supported Platforms
- **macOS** (Development/Developer ID distribution)
- **Linux** (AppImage/Flatpak)
- **Code Analysis & Testing**

### Required Secrets

For macOS Developer ID builds (optional, only for signed releases):
```
DEVELOPER_CERTIFICATE_BASE64    # Your Developer ID Application certificate (base64)
DEVELOPER_P12_PASSWORD          # Password for the .p12 certificate
DEVELOPER_SIGNING_IDENTITY      # Certificate name (e.g., "Developer ID Application: Your Name")
TEAM_ID                        # Your Apple Developer Team ID
APP_BUNDLE_ID                  # Your app's bundle identifier
KEYCHAIN_PASSWORD              # Random password for temporary keychain

# For notarization (optional)
NOTARIZE_USERNAME              # Your Apple ID email
NOTARIZE_PASSWORD              # App-specific password
```

### Workflow Triggers
- **Pull Requests:** Analysis and testing only
- **Push to develop:** Build unsigned versions
- **Push to main:** Build signed versions (if secrets configured)

### Artifacts
- **macOS:** Signed DMG for distribution outside App Store
- **Linux:** Tarball of built application

## 🛠️ Local Development

### Prerequisites
```bash
# Install Flutter
curl -o flutter.zip https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.5-stable.zip
unzip flutter.zip
export PATH="$PWD/flutter/bin:$PATH"

# macOS: Install Xcode and Command Line Tools
# Linux: Install build dependencies
sudo apt install cmake ninja-build libgtk-3-dev clang
```

### Building Locally
```bash
# Get dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Build for your platform
flutter build macos --release    # macOS
flutter build linux --release    # Linux
flutter build windows --release  # Windows
```

## 📱 Platform-Specific Notes

### macOS
- **App Store Version:** Fully sandboxed, distributed through Xcode Cloud
- **Development Version:** Uses Developer ID signing, distributed via GitHub Actions
- **Minimum Version:** macOS 11.0+
- **Features:** Full system tray integration, native notifications

### Linux
- **Distribution:** GitHub Actions builds
- **Packaging:** Tarball (can be extended to AppImage/Flatpak)
- **Features:** System tray, desktop notifications

### Windows
- **Status:** Ready for implementation
- **Features:** System tray, native notifications

## 🚀 Deployment Strategy

1. **Development:** Use GitHub Actions for testing and development builds
2. **App Store Release:** Use Xcode Cloud for automatic App Store distribution
3. **Alternative Distribution:** Use GitHub Actions for Developer ID signed builds

## 🔧 Troubleshooting

### Xcode Cloud Issues
- Check that Flutter version matches in `ci_post_clone.sh`
- Verify bundle identifier matches App Store Connect
- Ensure entitlements don't request unnecessary permissions

### GitHub Actions Issues
- Check Flutter version in workflow file
- Verify macOS deployment target is set correctly
- For signing issues, validate certificate format and passwords

### Code Signing
- Use `security find-identity -v -p codesigning` to list available identities
- Test signing locally: `codesign -s "Your Identity" path/to/app`
- Verify with: `codesign --verify --deep --strict path/to/app`

## 📋 Checklist for App Store Submission

- [ ] Bundle identifier configured in Xcode and App Store Connect
- [ ] App icons and metadata ready in App Store Connect
- [ ] Entitlements properly configured for sandboxing
- [ ] Xcode Cloud workflow successfully builds and archives
- [ ] App tested on various macOS versions
- [ ] Screenshots and app description prepared
- [ ] Privacy policy URL (if collecting any data)

## 🆘 Support

For build issues:
1. Check the CI logs in Xcode Cloud or GitHub Actions
2. Verify Flutter version compatibility
3. Test builds locally first
4. Ensure all required secrets/environment variables are set