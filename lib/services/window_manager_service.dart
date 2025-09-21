import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/platform_helpers.dart';

class WindowManagerService extends ChangeNotifier with WindowListener {
  static final WindowManagerService _instance = WindowManagerService._internal();
  factory WindowManagerService() => _instance;
  WindowManagerService._internal();

  bool _isInitialized = false;
  bool _isVisible = true;
  bool _minimizeToTray = PlatformHelpers.defaultMinimizeToTray;
  bool _closeToTray = PlatformHelpers.defaultCloseToTray;
  bool _startMinimized = PlatformHelpers.defaultStartMinimized;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isVisible => _isVisible;
  bool get minimizeToTray => _minimizeToTray;
  bool get closeToTray => _closeToTray;
  bool get startMinimized => _startMinimized;

  // Settings
  void setMinimizeToTray(bool value) {
    _minimizeToTray = value;
    notifyListeners();
  }

  void setCloseToTray(bool value) {
    _closeToTray = value;
    notifyListeners();
  }

  void setStartMinimized(bool value) {
    _startMinimized = value;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Only initialize on platforms that support window management
    if (!PlatformHelpers.supportsWindowManagement) {
      return;
    }

    try {
      // Add this instance as a window listener
      windowManager.addListener(this);
      
      // Set initial window properties
      await _configureWindow();
      
      _isInitialized = true;
      debugPrint('WindowManagerService initialized');
    } catch (e) {
      debugPrint('Failed to initialize WindowManagerService: $e');
    }
  }

  Future<void> _configureWindow() async {
    try {
      // Configure window options
      const windowOptions = WindowOptions(
        size: Size(1000, 700),
        minimumSize: Size(600, 500),
        center: true,
        backgroundColor: Color(0x00000000), // Transparent
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        windowButtonVisibility: true,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (_startMinimized) {
          await windowManager.minimize();
          _isVisible = false;
        } else {
          await windowManager.show();
          await windowManager.focus();
          _isVisible = true;
        }
      });

      // Set window title
      await windowManager.setTitle('Uptime Kuma Monitor');
      
    } catch (e) {
      debugPrint('Failed to configure window: $e');
    }
  }

  Future<void> showWindow() async {
    if (!_isInitialized) return;
    
    try {
      await windowManager.show();
      await windowManager.focus();
      _isVisible = true;
      notifyListeners();
      debugPrint('Window shown');
    } catch (e) {
      debugPrint('Failed to show window: $e');
    }
  }

  Future<void> hideWindow() async {
    if (!_isInitialized) return;
    
    try {
      await windowManager.hide();
      _isVisible = false;
      notifyListeners();
      debugPrint('Window hidden');
    } catch (e) {
      debugPrint('Failed to hide window: $e');
    }
  }

  Future<void> minimizeWindow() async {
    if (!_isInitialized) return;
    
    try {
      if (_minimizeToTray) {
        await hideWindow();
      } else {
        await windowManager.minimize();
        _isVisible = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to minimize window: $e');
    }
  }

  Future<void> toggleWindow() async {
    if (!_isInitialized) return;
    
    try {
      final currentlyVisible = await windowManager.isVisible();
      if (currentlyVisible) {
        await hideWindow();
      } else {
        await showWindow();
      }
    } catch (e) {
      debugPrint('Failed to toggle window: $e');
    }
  }

  Future<void> setWindowPosition(Offset position) async {
    if (!_isInitialized) return;
    
    try {
      await windowManager.setPosition(position);
    } catch (e) {
      debugPrint('Failed to set window position: $e');
    }
  }

  Future<void> setWindowSize(Size size) async {
    if (!_isInitialized) return;
    
    try {
      await windowManager.setSize(size);
    } catch (e) {
      debugPrint('Failed to set window size: $e');
    }
  }

  Future<void> centerWindow() async {
    if (!_isInitialized) return;
    
    try {
      await windowManager.center();
    } catch (e) {
      debugPrint('Failed to center window: $e');
    }
  }

  // WindowListener implementations
  @override
  void onWindowClose() {
    debugPrint('Window close event');
    
    if (_closeToTray || PlatformHelpers.shouldHideOnClose) {
      // Prevent default close behavior and hide to tray instead
      hideWindow();
    } else {
      // Allow normal close behavior
      dispose();
    }
  }

  @override
  void onWindowMinimize() {
    debugPrint('Window minimize event');
    
    if (_minimizeToTray) {
      hideWindow();
    } else {
      _isVisible = false;
      notifyListeners();
    }
  }

  @override
  void onWindowRestore() {
    debugPrint('Window restore event');
    _isVisible = true;
    notifyListeners();
  }

  @override
  void onWindowMaximize() {
    debugPrint('Window maximize event');
    _isVisible = true;
    notifyListeners();
  }

  @override
  void onWindowUnmaximize() {
    debugPrint('Window unmaximize event');
    _isVisible = true;
    notifyListeners();
  }

  @override
  void onWindowFocus() {
    debugPrint('Window focus event');
    _isVisible = true;
    notifyListeners();
  }

  @override
  void onWindowBlur() {
    debugPrint('Window blur event');
  }

  @override
  void onWindowResize() {
    debugPrint('Window resize event');
  }

  @override
  void onWindowMove() {
    debugPrint('Window move event');
  }

  @override
  void onWindowEnterFullScreen() {
    debugPrint('Window enter fullscreen event');
  }

  @override
  void onWindowLeaveFullScreen() {
    debugPrint('Window leave fullscreen event');
  }

  @override
  void dispose() {
    if (_isInitialized) {
      windowManager.removeListener(this);
      _isInitialized = false;
      debugPrint('WindowManagerService disposed');
    }
    super.dispose();
  }
}