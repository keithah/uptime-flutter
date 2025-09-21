#!/bin/bash

# Demo script to test system tray functionality
# This script will run the Flutter app in the background to test tray integration

echo "🚀 Starting Uptime Kuma Flutter Client with System Tray support..."
echo ""
echo "Features to test:"
echo "✅ System tray icon appears in system tray"
echo "✅ Icon color changes based on monitor status"
echo "✅ Left-click toggles window visibility"
echo "✅ Right-click shows context menu with:"
echo "   - Monitor status summary"
echo "   - Failed monitors list"
echo "   - Show/Hide window options"
echo "   - Refresh action"
echo "   - Settings access"
echo "   - Quit option"
echo "✅ Window minimizes to tray (if enabled in settings)"
echo "✅ Window close button hides to tray (if enabled in settings)"
echo ""
echo "Platform-specific behaviors:"
case "$(uname -s)" in
  Linux*)
    echo "📱 Linux: Left-click may show context menu, right-click for menu"
    echo "📱 Default: Minimize and close to tray enabled"
    ;;
  Darwin*)
    echo "🍎 macOS: Left-click toggles window, right-click for menu"
    echo "🍎 Default: Standard macOS hide to dock behavior"
    ;;
  CYGWIN*|MINGW32*|MSYS*|MINGW*)
    echo "🪟 Windows: Left-click toggles window, right-click for menu"
    echo "🪟 Default: Minimize and close to tray enabled"
    ;;
esac
echo ""
echo "Starting application..."

# Export Flutter path
export PATH="$PATH:/home/keith/src/flutter/bin"

# Run the Flutter application
flutter run -d linux --release

echo ""
echo "Application closed. System tray demo complete."