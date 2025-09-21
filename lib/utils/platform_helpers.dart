import 'dart:io';

class PlatformHelpers {
  static bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  
  static bool get supportsTrayIcon => isDesktop;
  static bool get supportsSystemNotifications => isDesktop || isMobile;
  static bool get supportsWindowManagement => isDesktop;
  
  // Platform-specific behaviors
  static bool get defaultMinimizeToTray {
    if (Platform.isWindows) return true;
    if (Platform.isLinux) return true;
    if (Platform.isMacOS) return false; // macOS typically hides to dock
    return false;
  }
  
  static bool get defaultCloseToTray {
    if (Platform.isWindows) return true;
    if (Platform.isLinux) return true;
    if (Platform.isMacOS) return false; // macOS apps typically quit on close
    return false;
  }
  
  static bool get defaultStartMinimized {
    return Platform.isWindows || Platform.isLinux;
  }
  
  static String get trayIconSize {
    if (Platform.isWindows) return '16'; // Windows typically uses 16x16
    if (Platform.isLinux) return '24';   // Linux varies, 24x24 is common
    if (Platform.isMacOS) return '16';   // macOS menubar is 16x16
    return '16';
  }
  
  static Duration get trayUpdateInterval {
    if (Platform.isWindows) return const Duration(milliseconds: 100);
    if (Platform.isLinux) return const Duration(milliseconds: 200);
    if (Platform.isMacOS) return const Duration(milliseconds: 50);
    return const Duration(milliseconds: 100);
  }
  
  // Notification behaviors
  static Duration get notificationDisplayDuration {
    if (Platform.isWindows) return const Duration(seconds: 5);
    if (Platform.isLinux) return const Duration(seconds: 4);
    if (Platform.isMacOS) return const Duration(seconds: 3);
    return const Duration(seconds: 4);
  }
  
  static bool get supportsBalloonNotifications {
    return Platform.isWindows;
  }
  
  static bool get supportsNativeMenus {
    return isDesktop;
  }
  
  // Window behaviors
  static bool get shouldHideOnClose {
    // On macOS, apps typically don't quit when window is closed
    return Platform.isMacOS;
  }
  
  static bool get shouldMinimizeOnStart {
    // Windows and Linux apps might start minimized to tray
    return Platform.isWindows || Platform.isLinux;
  }
  
  static bool get supportsTransparentWindows {
    return isDesktop;
  }
  
  // Tray menu behaviors
  static bool get useContextMenuOnLeftClick {
    return Platform.isLinux; // Linux often shows context menu on left click
  }
  
  static bool get useContextMenuOnRightClick {
    return Platform.isWindows || Platform.isMacOS;
  }
  
  static bool get supportsTrayTooltips {
    return isDesktop;
  }
  
  static bool get supportsAnimatedTrayIcons {
    return Platform.isWindows || Platform.isMacOS;
  }
  
  // Asset paths
  static String getTrayIconPath(String status) {
    final size = trayIconSize;
    return 'assets/icons/tray/icon_${status}_$size.png';
  }
  
  static List<String> getTrayIconSizes() {
    if (Platform.isWindows) return ['16', '24', '32'];
    if (Platform.isLinux) return ['16', '24', '32', '48'];
    if (Platform.isMacOS) return ['16', '32'];
    return ['16', '24', '32'];
  }
  
  // System integration
  static bool get supportsAutoStart {
    return isDesktop;
  }
  
  static bool get supportsGlobalHotkeys {
    return isDesktop;
  }
  
  static bool get supportsUrlProtocolHandling {
    return isDesktop;
  }
}