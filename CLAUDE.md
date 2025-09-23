# Flutter Uptime Kuma macOS Development Notes

## Project Overview
Flutter macOS app for monitoring Uptime Kuma servers with native status bar integration.

## Current Status ✅
- ✅ Flutter app builds and runs successfully
- ✅ Socket.IO authentication working (all 46 monitors loading)
- ✅ Clean UI implemented with monitor groups and counts
- ✅ Status bar integration functional (icon appears and clickable)
- ✅ LSUIElement=true configured in Info.plist

## Active Issue ⚠️
**Main window still appears despite menubar-only configuration**

### Problem
Despite setting `LSUIElement=true` and attempting to hide/close the main Flutter window in AppDelegate.swift, the app still launches with a separate window instead of being truly menubar-only.

### Current Implementation
- `AppDelegate.swift` creates dedicated FlutterEngine for popover
- StatusBarController shows popover on click
- Main window is hidden/closed in `applicationDidFinishLaunching`
- Info.plist has `LSUIElement=true`

### Attempted Solutions
1. Hide main window before super.applicationDidFinishLaunching()
2. Close main window after super.applicationDidFinishLaunching()
3. Create separate FlutterEngine for popover content
4. Updated StatusBarController to not rely on main window

### Next Steps
Need to investigate why Flutter main window still appears. Possible solutions:
- Override window creation in FlutterAppDelegate
- Use NSApplicationDelegate instead of FlutterAppDelegate
- Prevent main window from being created entirely
- Research Flutter macOS headless mode

## File Structure
- `macos/Runner/AppDelegate.swift` - Main app delegate with menubar setup
- `macos/StatusBarController.swift` - Native status bar implementation
- `lib/ui/screens/home_screen.dart` - Clean monitor list UI
- `lib/services/uptime_kuma_service.dart` - Socket.IO integration

## Test Commands
```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter run -d macos
```

## Git Status
Ready to commit current progress with documented issue.