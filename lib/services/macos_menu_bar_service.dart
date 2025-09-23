import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/monitor_status.dart';
import 'uptime_kuma_service.dart';
import 'window_manager_service.dart';

class MacOSMenuBarService extends ChangeNotifier {
  static final MacOSMenuBarService _instance = MacOSMenuBarService._internal();
  factory MacOSMenuBarService() => _instance;
  MacOSMenuBarService._internal();

  static const platform = MethodChannel('com.example.uptime_flutter/menubar');

  bool _isInitialized = false;
  MonitorStatus _currentStatus = MonitorStatus.unknown;

  // Services
  UptimeKumaService? _uptimeService;
  WindowManagerService? _windowService;

  // Getters
  bool get isInitialized => _isInitialized;
  MonitorStatus get currentStatus => _currentStatus;

  Future<void> initialize({
    required UptimeKumaService uptimeService,
    required WindowManagerService windowService,
  }) async {
    if (_isInitialized || !Platform.isMacOS) return;

    _uptimeService = uptimeService;
    _windowService = windowService;

    try {
      // Set up method channel handler
      platform.setMethodCallHandler(_handleMethodCall);

      // Initialize the menu bar
      await _createMenuBar();

      // Listen to uptime service changes
      _uptimeService!.addListener(_onUptimeServiceChange);

      _isInitialized = true;
      debugPrint('MacOS menu bar initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize MacOS menu bar: $e');
    }
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;

    _uptimeService?.removeListener(_onUptimeServiceChange);
    _isInitialized = false;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'showWindow':
        await _windowService?.showWindow();
        break;
      case 'hideWindow':
        await _windowService?.hideWindow();
        break;
      case 'toggleWindow':
        await _windowService?.toggleWindow();
        break;
      case 'refreshData':
        await _uptimeService?.refreshData();
        break;
      case 'quit':
        await _windowService?.quit();
        break;
    }
  }

  void _onUptimeServiceChange() {
    if (_uptimeService == null) return;

    final newStatus = _uptimeService!.overallStatus;
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _updateMenuBar();
    }
  }

  Future<void> _createMenuBar() async {
    try {
      final statusText = _getStatusText(_currentStatus);

      await platform.invokeMethod('createMenuBar', {
        'status': statusText,
        'iconName': _getIconName(_currentStatus),
      });
    } catch (e) {
      debugPrint('Failed to create menu bar: $e');
    }
  }

  Future<void> _updateMenuBar() async {
    if (!_isInitialized) return;

    try {
      final statusText = _getStatusText(_currentStatus);

      await platform.invokeMethod('updateMenuBar', {
        'status': statusText,
        'iconName': _getIconName(_currentStatus),
      });
    } catch (e) {
      debugPrint('Failed to update menu bar: $e');
    }
  }

  String _getStatusText(MonitorStatus status) {
    switch (status) {
      case MonitorStatus.up:
        return 'All systems operational';
      case MonitorStatus.down:
        return 'System issues detected';
      case MonitorStatus.pending:
        return 'Partial system issues';
      case MonitorStatus.paused:
        return 'Monitoring paused';
      default:
        return 'Status unknown';
    }
  }

  String _getIconName(MonitorStatus status) {
    switch (status) {
      case MonitorStatus.up:
        return 'checkmark.circle';
      case MonitorStatus.down:
        return 'xmark.circle';
      case MonitorStatus.pending:
        return 'exclamationmark.triangle';
      case MonitorStatus.paused:
        return 'pause.circle';
      default:
        return 'questionmark.circle';
    }
  }
}