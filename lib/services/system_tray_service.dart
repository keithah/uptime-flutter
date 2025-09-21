import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import '../models/monitor_status.dart';
import '../utils/platform_helpers.dart';
import 'uptime_kuma_service.dart';
import 'notification_service.dart';

class SystemTrayService extends ChangeNotifier {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  final SystemTray _systemTray = SystemTray();
  bool _isInitialized = false;
  bool _isVisible = false;
  MonitorStatus _currentStatus = MonitorStatus.unknown;
  
  // Menu items
  Menu? _menu;
  
  // Services
  UptimeKumaService? _uptimeService;
  NotificationService? _notificationService;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isVisible => _isVisible;
  MonitorStatus get currentStatus => _currentStatus;

  Future<void> initialize({
    required UptimeKumaService uptimeService,
    required NotificationService notificationService,
  }) async {
    if (_isInitialized) return;
    
    // Only initialize on platforms that support tray icons
    if (!PlatformHelpers.supportsTrayIcon) {
      return;
    }

    _uptimeService = uptimeService;
    _notificationService = notificationService;
    
    try {
      // Set initial icon
      await _updateTrayIcon(_currentStatus);
      
      // Create initial menu
      await _buildMenu();
      
      // Set up tray
      if (_menu != null) {
        await _systemTray.setContextMenu(_menu!);
      }
      
      // Set up click handlers
      _systemTray.registerSystemTrayEventHandler(_onTrayEvent);
      
      _isInitialized = true;
      _isVisible = true;
      
      // Listen to uptime service changes
      _uptimeService!.addListener(_onUptimeServiceChange);
      
      debugPrint('System tray initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize system tray: $e');
    }
  }

  Future<void> _onTrayEvent(String eventName) async {
    debugPrint('System tray event: $eventName');
    
    switch (eventName) {
      case kSystemTrayEventClick:
        if (PlatformHelpers.useContextMenuOnLeftClick) {
          // On Linux, left click often shows context menu
          // Context menu will be shown automatically
        } else {
          // On Windows/macOS, left click toggles window
          await toggleWindow();
        }
        break;
      case 'secondaryClick':
        // Context menu will be shown automatically
        break;
      case 'rightClick':
        if (PlatformHelpers.useContextMenuOnRightClick) {
          // Context menu will be shown automatically
        }
        break;
    }
  }

  void _onUptimeServiceChange() {
    if (_uptimeService == null) return;
    
    final newStatus = _uptimeService!.overallStatus;
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _updateTrayIcon(newStatus);
      _buildMenu(); // Rebuild menu with updated status
    }
  }

  Future<void> _updateTrayIcon(MonitorStatus status) async {
    try {
      String statusName;
      String tooltip;
      
      switch (status) {
        case MonitorStatus.up:
          statusName = 'up';
          tooltip = 'Uptime Kuma - All systems operational';
          break;
        case MonitorStatus.down:
          statusName = 'down';
          tooltip = 'Uptime Kuma - System issues detected';
          break;
        case MonitorStatus.pending:
          statusName = 'pending';
          tooltip = 'Uptime Kuma - Partial system issues';
          break;
        case MonitorStatus.paused:
          statusName = 'unknown';
          tooltip = 'Uptime Kuma - Monitoring paused';
          break;
        default:
          statusName = 'unknown';
          tooltip = 'Uptime Kuma - Status unknown';
      }
      
      final iconPath = PlatformHelpers.getTrayIconPath(statusName);
      
      await _systemTray.setImage(iconPath);
      
      if (PlatformHelpers.supportsTrayTooltips) {
        await _systemTray.setToolTip(tooltip);
      }
      
    } catch (e) {
      debugPrint('Failed to update tray icon: $e');
    }
  }

  Future<void> _buildMenu() async {
    try {
      _menu = Menu();
      
      // Status section
      if (_uptimeService != null) {
        final service = _uptimeService!;
        
        _menu!.buildFrom([
          MenuItemLabel(
            label: '${service.menuBarTitle} Uptime Kuma',
            enabled: false,
          ),
          MenuSeparator(),
        ]);
        
        if (service.isConnected) {
          // Online/Total monitors
          _menu!.buildFrom([
            MenuItemLabel(
              label: '${service.onlineMonitors}/${service.totalMonitors} monitors online',
              enabled: false,
            ),
          ]);
          
          // Failed monitors (if any)
          final failedMonitors = service.failedMonitors;
          if (failedMonitors.isNotEmpty) {
            _menu!.buildFrom([
              MenuSeparator(),
              MenuItemLabel(
                label: 'Failed Monitors:',
                enabled: false,
              ),
            ]);
            
            for (final monitor in failedMonitors.take(3)) {
              _menu!.buildFrom([
                MenuItemLabel(
                  label: '  ❌ ${monitor.name}',
                  enabled: false,
                ),
              ]);
            }
            
            if (failedMonitors.length > 3) {
              _menu!.buildFrom([
                MenuItemLabel(
                  label: '  ... and ${failedMonitors.length - 3} more',
                  enabled: false,
                ),
              ]);
            }
          }
          
          // Last update
          if (service.lastUpdate != null) {
            final lastUpdate = service.lastUpdate!;
            final now = DateTime.now();
            final diff = now.difference(lastUpdate);
            
            String timeAgo;
            if (diff.inMinutes < 1) {
              timeAgo = 'just now';
            } else if (diff.inMinutes < 60) {
              timeAgo = '${diff.inMinutes}m ago';
            } else {
              timeAgo = '${diff.inHours}h ago';
            }
            
            _menu!.buildFrom([
              MenuSeparator(),
              MenuItemLabel(
                label: 'Updated $timeAgo',
                enabled: false,
              ),
            ]);
          }
        } else {
          // Connection status
          if (service.isLoading) {
            _menu!.buildFrom([
              MenuItemLabel(
                label: '🔄 Connecting...',
                enabled: false,
              ),
            ]);
          } else if (service.errorMessage != null) {
            _menu!.buildFrom([
              MenuItemLabel(
                label: '❌ Connection failed',
                enabled: false,
              ),
            ]);
          } else {
            _menu!.buildFrom([
              MenuItemLabel(
                label: '⚫ Not connected',
                enabled: false,
              ),
            ]);
          }
        }
      }
      
      // Actions
      _menu!.buildFrom([
        MenuSeparator(),
        MenuItemLabel(
          label: 'Show Window',
          onClicked: (menuItem) => showWindow(),
        ),
        MenuItemLabel(
          label: 'Hide Window', 
          onClicked: (menuItem) => hideWindow(),
        ),
        MenuSeparator(),
      ]);
      
      if (_uptimeService != null) {
        _menu!.buildFrom([
          MenuItemLabel(
            label: 'Refresh',
            onClicked: (menuItem) => _uptimeService!.fetchData(),
          ),
          MenuSeparator(),
        ]);
      }
      
      // Settings and Exit
      _menu!.buildFrom([
        MenuItemLabel(
          label: 'Settings',
          onClicked: (menuItem) async {
            await showWindow();
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Quit',
          onClicked: (menuItem) => quit(),
        ),
      ]);
      
      if (_isInitialized && _menu != null) {
        await _systemTray.setContextMenu(_menu!);
      }
      
    } catch (e) {
      debugPrint('Failed to build tray menu: $e');
    }
  }

  Future<void> showWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
      debugPrint('Window shown');
    } catch (e) {
      debugPrint('Failed to show window: $e');
    }
  }

  Future<void> hideWindow() async {
    try {
      await windowManager.hide();
      debugPrint('Window hidden');
    } catch (e) {
      debugPrint('Failed to hide window: $e');
    }
  }

  Future<void> toggleWindow() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        await hideWindow();
      } else {
        await showWindow();
      }
    } catch (e) {
      debugPrint('Failed to toggle window: $e');
    }
  }

  Future<void> quit() async {
    try {
      debugPrint('Quitting application...');
      
      // Clean up
      await dispose();
      
      // Quit the application
      await windowManager.destroy();
      
    } catch (e) {
      debugPrint('Error during quit: $e');
    }
  }

  Future<void> updateMenu() async {
    if (!_isInitialized) return;
    await _buildMenu();
  }

  Future<void> showNotification(String title, String message) async {
    try {
      if (_notificationService != null) {
        await _notificationService!.showNotification(
          title: title,
          body: message,
        );
      }
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  Future<void> setStatus(MonitorStatus status) async {
    if (status != _currentStatus) {
      _currentStatus = status;
      await _updateTrayIcon(status);
      await _buildMenu();
      notifyListeners();
    }
  }

  @override
  Future<void> dispose() async {
    if (_isInitialized) {
      try {
        _uptimeService?.removeListener(_onUptimeServiceChange);
        await _systemTray.destroy();
        _isInitialized = false;
        _isVisible = false;
        debugPrint('System tray disposed');
      } catch (e) {
        debugPrint('Error disposing system tray: $e');
      }
    }
    super.dispose();
  }
}