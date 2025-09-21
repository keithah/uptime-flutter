# Uptime Kuma Flutter Client

A cross-platform Flutter application for monitoring Uptime Kuma instances with real-time notifications and system tray support.

## 🎯 Features

- **Cross-platform**: Works on Linux, Windows, macOS, iOS, and Android
- **Real-time monitoring**: WebSocket connection to Uptime Kuma server
- **System notifications**: Native notifications for monitor status changes
- **System tray integration**: 
  - Color-coded tray icons showing overall system status
  - Context menu with monitor status and quick actions
  - Platform-specific behaviors (minimize to tray, close to tray)
  - Click to show/hide window functionality
- **Advanced window management**:
  - Minimize to system tray
  - Close to system tray instead of quitting
  - Start minimized option
  - Platform-appropriate defaults
- **Mobile-friendly**: Optimized UI for mobile devices
- **Adaptive design**: Material Design on Android, Cupertino on iOS
- **Dark/light themes**: Automatic theme switching based on system preferences

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.24.5 or later)
- For Linux desktop: `cmake`, `ninja-build`, `libgtk-3-dev`, `clang`
- An Uptime Kuma server instance

### Installation

1. Clone this repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate model files:
   ```bash
   dart run build_runner build
   ```

4. Run the application:
   ```bash
   # For desktop (Linux/Windows/macOS)
   flutter run -d linux
   flutter run -d windows
   flutter run -d macos
   
   # For mobile
   flutter run -d android
   flutter run -d ios
   ```

### Building

```bash
# Linux
flutter build linux

# Windows
flutter build windows

# macOS
flutter build macos

# Android APK
flutter build apk

# iOS
flutter build ios
```

## 🔧 Configuration

On first launch, you'll be prompted to configure your Uptime Kuma server connection:

1. **Server URL**: Your Uptime Kuma server URL (e.g., `http://localhost:3001`)
2. **Username**: Your Uptime Kuma username
3. **Password**: Your Uptime Kuma password

### Settings

The app includes various configuration options:

- **Notifications**: Enable/disable notifications for monitor status changes
- **Display Options**: Customize refresh interval, compact mode, and response time display
- **Connection Testing**: Test your server connection before saving settings

## 🏗️ Architecture

The Flutter app is built with:

- **State Management**: Provider pattern for reactive state management
- **WebSocket Client**: Socket.IO client for real-time communication
- **Local Storage**: SharedPreferences for settings persistence
- **Notifications**: flutter_local_notifications for cross-platform alerts
- **Desktop Integration**: window_manager and system_tray for desktop features

### Project Structure

```
lib/
├── models/              # Data models and JSON serialization
│   ├── monitor.dart
│   ├── heartbeat.dart
│   ├── monitor_status.dart
│   ├── settings.dart
│   └── monitor_group.dart
├── services/            # Business logic and API services
│   ├── uptime_kuma_service.dart
│   ├── settings_service.dart
│   ├── notification_service.dart
│   ├── system_tray_service.dart
│   └── window_manager_service.dart
├── ui/
│   ├── screens/         # App screens
│   │   ├── home_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/         # Reusable UI components
│       ├── monitor_card.dart
│       ├── monitor_group_card.dart
│       ├── status_header.dart
│       └── connection_status_indicator.dart
└── main.dart           # App entry point
```

## 📱 Platform-Specific Features

### Desktop (Linux/Windows/macOS)
- **System tray integration**: 
  - Color-coded status icons (green=up, red=down, orange=pending, gray=unknown)
  - Dynamic context menu showing monitor status and recent failures
  - Left-click to toggle window visibility (Windows/macOS)
  - Right-click for context menu
- **Window management**:
  - Minimize to tray option
  - Close to tray instead of quit
  - Start minimized option
  - Platform-specific defaults (Windows/Linux minimize to tray, macOS hides to dock)
- **Desktop notifications**: Native system notifications for status changes
- **Navigation rail**: Optimized layout for desktop screens

### Mobile (iOS/Android)
- Bottom navigation
- Pull-to-refresh
- Mobile-optimized layouts
- Push notifications (planned)

## 🔗 Uptime Kuma Integration

The app connects to Uptime Kuma via WebSocket and handles these events:

- `MONITOR_LIST` - Initial monitor data
- `HEARTBEAT` - Real-time monitor status updates  
- `HEARTBEAT_LIST` - Historical heartbeat data
- `UPTIME` - Uptime percentage data
- `AVG_PING` - Average ping statistics

### Authentication

The app supports username/password authentication with Uptime Kuma:

```dart
final loginData = {
  'username': 'your-username',
  'password': 'your-password',
  'token': '', // API token support planned
};
```

## 🛠️ Development

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Code Generation

When you modify model classes with JSON annotations:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 🚧 Roadmap

- [ ] API token authentication
- [ ] Background sync for mobile
- [ ] Push notifications for mobile
- [ ] Multiple server instances support
- [ ] Custom themes
- [ ] Monitor grouping and filtering
- [ ] Export/import settings
- [ ] Offline support with local caching

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🆘 Troubleshooting

### Connection Issues

1. Verify your Uptime Kuma server is accessible
2. Check the WebSocket endpoint (usually `/socket.io/`)
3. Verify your authentication credentials
4. Check firewall/network settings

### Build Issues

#### Linux
```bash
# Install required dependencies
sudo apt install cmake ninja-build libgtk-3-dev clang
```

#### Windows
- Install Visual Studio with C++ development tools
- Ensure Windows SDK is installed

#### macOS
- Install Xcode and Command Line Tools
- Ensure CocoaPods is installed

### Performance

- The app automatically limits stored heartbeats to the last 50 per monitor
- Refresh intervals can be adjusted in settings (10-300 seconds)
- Compact mode reduces UI overhead for large monitor lists

---

**Migration from Swift**: This Flutter app provides cross-platform compatibility while maintaining feature parity with the original Swift macOS menubar application.
