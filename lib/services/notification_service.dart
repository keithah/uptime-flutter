import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/platform_helpers.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  bool _permissionsGranted = false;
  
  // Notification settings
  bool _notificationsEnabled = true;
  bool _notifyOnDown = true;
  bool _notifyOnUp = true;
  bool _notifyOnPending = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  NotificationPriority _priority = NotificationPriority.high;
  
  // Notification history
  final List<NotificationRecord> _notificationHistory = [];
  final int _maxHistorySize = 100;
  
  // Rate limiting
  final Map<String, DateTime> _lastNotificationTime = {};
  final Duration _rateLimitDuration = const Duration(minutes: 5);

  // Getters
  bool get isInitialized => _isInitialized;
  bool get permissionsGranted => _permissionsGranted;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get notifyOnDown => _notifyOnDown;
  bool get notifyOnUp => _notifyOnUp;
  bool get notifyOnPending => _notifyOnPending;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  NotificationPriority get priority => _priority;
  List<NotificationRecord> get notificationHistory => List.unmodifiable(_notificationHistory);

  // Settings methods
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  void setNotifyOnDown(bool enabled) {
    _notifyOnDown = enabled;
    notifyListeners();
  }

  void setNotifyOnUp(bool enabled) {
    _notifyOnUp = enabled;
    notifyListeners();
  }

  void setNotifyOnPending(bool enabled) {
    _notifyOnPending = enabled;
    notifyListeners();
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    notifyListeners();
  }

  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    notifyListeners();
  }

  void setPriority(NotificationPriority priority) {
    _priority = priority;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Only initialize on platforms that support notifications
    if (!PlatformHelpers.supportsSystemNotifications) {
      debugPrint('Platform does not support system notifications');
      _isInitialized = true;
      return;
    }

    try {
      // Initialize settings for different platforms
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const DarwinInitializationSettings initializationSettingsMacOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(
        defaultActionName: 'Open Uptime Kuma',
        defaultIcon: AssetsLinuxIcon('assets/icons/tray/icon_up_32.png'),
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: initializationSettingsMacOS,
        linux: initializationSettingsLinux,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      _permissionsGranted = await _requestPermissions();
      
      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
      
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
      _isInitialized = true; // Mark as initialized even if failed
    }
  }

  Future<bool> _requestPermissions() async {
    bool granted = false;
    
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        final iosImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
        final macOSImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
        
        if (Platform.isIOS && iosImplementation != null) {
          granted = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
        } else if (Platform.isMacOS && macOSImplementation != null) {
          granted = await macOSImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
        }
      } else if (Platform.isAndroid) {
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          granted = await androidImplementation.requestNotificationsPermission() ?? false;
        }
      } else if (Platform.isLinux) {
        // Linux typically doesn't require explicit permission requests
        granted = true;
      }
      
      debugPrint('Notification permissions granted: $granted');
      return granted;
      
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    String? iconPath,
    bool? playSound,
    bool? enableVibration,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_notificationsEnabled || !_permissionsGranted) {
      debugPrint('Notifications disabled or no permissions');
      return;
    }

    // Check rate limiting
    final key = '$title:$body';
    if (_isRateLimited(key)) {
      debugPrint('Notification rate limited: $title');
      return;
    }

    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final bool shouldPlaySound = playSound ?? _soundEnabled;
    final bool shouldVibrate = enableVibration ?? _vibrationEnabled;

    // Create platform-specific notification details
    final androidDetails = AndroidNotificationDetails(
      'uptime_kuma_monitor_channel',
      'Monitor Status',
      channelDescription: 'Notifications for Uptime Kuma monitor status changes',
      importance: _getAndroidImportance(priority),
      priority: _getAndroidPriority(priority),
      icon: iconPath != null ? iconPath.split('/').last.split('.').first : '@mipmap/ic_launcher',
      playSound: shouldPlaySound,
      enableVibration: shouldVibrate,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
      actions: [
        const AndroidNotificationAction(
          'open_app',
          'Open App',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss',
          'Dismiss',
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: shouldPlaySound,
      sound: shouldPlaySound ? null : '', // Use default sound or silent
      categoryIdentifier: 'monitor_status',
    );

    final macOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: shouldPlaySound,
      sound: shouldPlaySound ? null : '',
      categoryIdentifier: 'monitor_status',
    );

    final linuxDetails = LinuxNotificationDetails(
      icon: iconPath != null ? AssetsLinuxIcon(iconPath) : null,
      category: LinuxNotificationCategory.deviceError,
      urgency: _getLinuxUrgency(priority),
      timeout: LinuxNotificationTimeout.fromDuration(
        PlatformHelpers.notificationDisplayDuration,
      ),
      actions: [
        const LinuxNotificationAction(
          key: 'open_app',
          label: 'Open App',
        ),
      ],
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macOSDetails,
      linux: linuxDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      // Add to history
      _addToHistory(NotificationRecord(
        id: notificationId,
        title: title,
        body: body,
        timestamp: DateTime.now(),
        priority: priority,
        payload: payload,
      ));

      // Update rate limiting
      _updateRateLimit(key);

      debugPrint('Notification shown: $title');

    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  Future<void> showMonitorDownNotification({
    required String monitorName,
    String? url,
  }) async {
    if (!_notifyOnDown) return;
    
    await showNotification(
      title: 'Monitor Down: $monitorName',
      body: 'Monitor $monitorName is no longer responding',
      payload: 'monitor_down:$monitorName',
      priority: NotificationPriority.high,
    );
  }

  Future<void> showMonitorUpNotification({
    required String monitorName,
    String? url,
  }) async {
    if (!_notifyOnUp) return;
    
    await showNotification(
      title: 'Monitor Recovered: $monitorName',
      body: 'Monitor $monitorName is back online',
      payload: 'monitor_up:$monitorName',
      priority: NotificationPriority.normal,
    );
  }

  Future<void> showMonitorPendingNotification({
    required String monitorName,
    String? url,
  }) async {
    if (!_notifyOnPending) return;
    
    await showNotification(
      title: 'Monitor Warning: $monitorName',
      body: 'Monitor $monitorName is experiencing issues',
      payload: 'monitor_pending:$monitorName',
      priority: NotificationPriority.normal,
    );
  }

  Future<void> showOverallStatusNotification({
    required String title,
    required String body,
  }) async {
    await showNotification(
      title: title,
      body: body,
      payload: 'overall_status',
    );
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    debugPrint('Notification tapped with payload: $payload');
    
    // Handle notification tap
    if (payload != null) {
      // Parse payload and handle accordingly
      if (payload.startsWith('monitor_down:') || payload.startsWith('monitor_up:')) {
        // Handle monitor-specific notification
        final monitorName = payload.split(':')[1];
        debugPrint('Monitor notification for: $monitorName');
      } else if (payload == 'overall_status') {
        // Handle overall status notification
        debugPrint('Overall status notification tapped');
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Helper methods for rate limiting and history
  bool _isRateLimited(String key) {
    if (!_lastNotificationTime.containsKey(key)) {
      return false;
    }
    
    final lastTime = _lastNotificationTime[key]!;
    final now = DateTime.now();
    return now.difference(lastTime) < _rateLimitDuration;
  }

  void _updateRateLimit(String key) {
    _lastNotificationTime[key] = DateTime.now();
  }

  void _addToHistory(NotificationRecord record) {
    _notificationHistory.insert(0, record);
    
    // Limit history size
    if (_notificationHistory.length > _maxHistorySize) {
      _notificationHistory.removeRange(_maxHistorySize, _notificationHistory.length);
    }
    
    notifyListeners();
  }

  void clearNotificationHistory() {
    _notificationHistory.clear();
    notifyListeners();
  }

  // Platform-specific helper methods
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.max:
        return Importance.max;
    }
  }

  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }

  LinuxNotificationUrgency _getLinuxUrgency(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return LinuxNotificationUrgency.low;
      case NotificationPriority.normal:
        return LinuxNotificationUrgency.normal;
      case NotificationPriority.high:
      case NotificationPriority.max:
        return LinuxNotificationUrgency.critical;
    }
  }
}

// Notification data models
enum NotificationPriority {
  low,
  normal,
  high,
  max,
}

class NotificationRecord {
  final int id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationPriority priority;
  final String? payload;

  NotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.priority,
    this.payload,
  });

  @override
  String toString() {
    return 'NotificationRecord(id: $id, title: $title, timestamp: $timestamp, priority: $priority)';
  }
}