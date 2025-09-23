import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/monitor.dart';
import '../models/heartbeat.dart';
import '../models/monitor_status.dart';
import '../models/monitor_group.dart';
import '../models/settings.dart';
import 'notification_service.dart';

class UptimeKumaService extends ChangeNotifier {
  // Socket.IO client
  io.Socket? _socket;
  
  // Data
  final Map<int, Monitor> _monitors = {};
  final Map<int, List<Heartbeat>> _heartbeats = {};
  final Map<int, double> _uptimes = {};
  final Map<int, MonitorStatus> _previousStatuses = {};
  
  // UI state
  bool _isConnected = false;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdate;
  
  // Settings
  UptimeKumaSettings _settings = const UptimeKumaSettings();
  
  // Notification service
  NotificationService? _notificationService;
  
  // Computed properties
  List<MonitorGroup> _groups = [];
  List<Monitor> _standaloneMonitors = [];
  
  // Getters
  Map<int, Monitor> get monitors => Map.unmodifiable(_monitors);
  Map<int, List<Heartbeat>> get heartbeats => Map.unmodifiable(_heartbeats);
  Map<int, double> get uptimes => Map.unmodifiable(_uptimes);
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdate => _lastUpdate;
  UptimeKumaSettings get settings => _settings;
  List<MonitorGroup> get groups => List.unmodifiable(_groups);
  List<Monitor> get standaloneMonitors => List.unmodifiable(_standaloneMonitors);
  
  // Computed getters
  int get totalMonitors => _monitors.length;
  int get onlineMonitors => _monitors.values
      .where((monitor) => getMonitorStatus(monitor.id) == MonitorStatus.up)
      .length;
  
  MonitorStatus get overallStatus {
    if (_monitors.isEmpty) return MonitorStatus.unknown;
    
    bool hasDown = false;
    bool hasPending = false;
    bool hasUp = false;
    
    for (final monitor in _monitors.values) {
      final status = getMonitorStatus(monitor.id);
      switch (status) {
        case MonitorStatus.down:
          hasDown = true;
          break;
        case MonitorStatus.up:
          hasUp = true;
          break;
        case MonitorStatus.pending:
          hasPending = true;
          break;
        default:
          break;
      }
    }
    
    if (hasDown) return MonitorStatus.down;
    if (hasPending) return MonitorStatus.pending;
    if (hasUp) return MonitorStatus.up;
    return MonitorStatus.unknown;
  }
  
  String get menuBarTitle {
    if (totalMonitors == 0) return '❓';
    if (onlineMonitors == totalMonitors) return '🌍';
    return '$onlineMonitors/$totalMonitors';
  }
  
  List<Monitor> get failedMonitors => _monitors.values
      .where((monitor) => getMonitorStatus(monitor.id) == MonitorStatus.down)
      .toList();
  
  void updateSettings(UptimeKumaSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
    
    if (_isConnected) {
      disconnect();
    }
    connect();
  }
  
  Future<void> connect() async {
    if (!_settings.isConfigured) {
      _setError('Please configure server URL, username, and password');
      return;
    }
    
    _log('Starting connection to ${_settings.serverUrl}');
    _setLoading(true);
    _setError(null);
    
    try {
      // First establish polling session to get session ID
      await _establishPollingSession();
    } catch (e) {
      _log('Connection failed: $e');
      _setError('Connection failed: $e');
      _setLoading(false);
    }
  }
  
  Future<void> _establishPollingSession() async {
    final baseUrl = _settings.serverUrl.replaceAll(RegExp(r'/$'), '');
    final pollingUrl = '$baseUrl/socket.io/?EIO=4&transport=polling';
    
    _log('Establishing polling session: $pollingUrl');
    
    try {
      // For now, skip the polling session and connect directly to WebSocket
      await _connectWebSocket();
    } catch (e) {
      _log('Polling session failed: $e');
      rethrow;
    }
  }
  
  Future<void> _connectWebSocket() async {
    final baseUrl = _settings.serverUrl.replaceAll(RegExp(r'/$'), '');
    var socketUrl = baseUrl.replaceAll('http://', 'ws://');
    socketUrl = socketUrl.replaceAll('https://', 'wss://');
    
    _log('WebSocket URL: $socketUrl');
    
    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableForceNew()
          .setExtraHeaders({'Connection': 'upgrade'})
          .build(),
    );
    
    _setupSocketListeners();
    _socket!.connect();
  }
  
  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      _log('Socket.IO connected successfully!');
      _setConnected(true);
      _setLoading(false);

      // Start authentication immediately using callback-based approach
      _authenticate();
    });
    
    _socket!.onDisconnect((_) {
      _log('Socket.IO disconnected');
      _setConnected(false);
    });
    
    _socket!.onConnectError((error) {
      _log('Socket.IO connection error: $error');
      _setError('Connection error: $error');
      _setConnected(false);
      _setLoading(false);
    });
    
    _socket!.onError((error) {
      _log('Socket.IO error: $error');
      _setError('Socket error: $error');
    });
    
    // Handle authentication response
    _socket!.on('login', (data) => _handleLoginStatus(data));
    _socket!.on('loginStatus', (data) => _handleLoginStatus(data));
    _socket!.on('auth', (data) => _handleLoginStatus(data));
    _socket!.on('authStatus', (data) => _handleLoginStatus(data));
    _socket!.on('needAuth', (data) => _handleNeedAuth(data));
    _socket!.on('autoAuth', (data) => _handleAutoAuth(data));
    _socket!.on('authRequired', (data) => _handleNeedAuth(data));
    _socket!.on('error', (data) => _handleError(data));
    
    // Handle monitor data events
    _socket!.on('MONITOR_LIST', (data) => _processMonitorList(data));
    _socket!.on('monitorList', (data) => _processMonitorList(data));
    _socket!.on('monitor:list', (data) => _processMonitorList(data));
    _socket!.on('monitors', (data) => _processMonitorList(data));
    _socket!.on('getMonitors', (data) => _processMonitorList(data));
    _socket!.on('dashboard', (data) => _processDashboard(data));
    _socket!.on('HEARTBEAT', (data) => _processHeartbeat(data));
    _socket!.on('heartbeat', (data) => _processHeartbeat(data));
    _socket!.on('HEARTBEAT_LIST', (data) => _processHeartbeatList(data));
    _socket!.on('heartbeatList', (data) => _processHeartbeatList(data));
    _socket!.on('UPTIME', (data) => _processUptime(data));
    _socket!.on('uptime', (data) => _processUptime(data));
    _socket!.on('AVG_PING', (data) => _processAvgPing(data));
    _socket!.on('avgPing', (data) => _processAvgPing(data));
    _socket!.on('info', (data) => _handleServerInfo(data));

    // Debug: Listen to all events
    _socket!.onAny((event, data) {
      _log('Socket event received: $event with data: $data');
    });
  }
  
  void _authenticate() {
    _log('Sending authentication request with callback...');

    // Use the same format as the working Swift implementation
    final loginData = {
      'username': _settings.username,
      'password': _settings.password,
      'token': '',
    };

    _log('Authentication data: username=${_settings.username}, password=${_settings.password.isNotEmpty ? '(set)' : '(empty)'}');

    // Send login with callback acknowledgment (matching Swift implementation)
    _socket!.emitWithAck('login', loginData, ack: (data) {
      _log('Login acknowledgment received: $data');
      _handleLoginStatus(data);
    });
    _log('Sent login event with callback acknowledgment');
  }
  
  void _handleLoginStatus(dynamic data) {
    _log('Login status received: $data');
    
    if (data is Map<String, dynamic>) {
      final ok = data['ok'] as bool?;
      if (ok == true) {
        _log('Authentication successful!');
        _requestMonitorList();
      } else {
        final msg = data['msg'] as String? ?? 'Unknown error';
        _log('Authentication failed: $msg');
        _setError('Authentication failed: $msg');
        _setConnected(false);
        _setLoading(false);
      }
    }
  }
  
  void _handleServerInfo(dynamic data) {
    _log('Server info received: $data');
    if (data is Map<String, dynamic> && data.containsKey('version')) {
      _log('Server version detected: ${data['version']} - authentication complete!');
    }
  }

  void _handleNeedAuth(dynamic data) {
    _log('NeedAuth received: $data');
    // Server is asking for authentication, so we should send it now
    _authenticate();
  }

  void _handleAutoAuth(dynamic data) {
    _log('AutoAuth received: $data');
    if (data is Map<String, dynamic>) {
      final success = data['success'] as bool? ?? false;
      if (success) {
        _log('Auto authentication successful!');
        _requestMonitorList();
      } else {
        _log('Auto authentication failed, trying manual auth');
        _authenticate();
      }
    }
  }

  void _handleError(dynamic data) {
    _log('Socket error received: $data');
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['msg'] ?? data.toString();
      _setError('Server error: $message');
    } else {
      _setError('Server error: $data');
    }
  }
  
  void _requestMonitorList() {
    _log('According to uptime-kuma-api, monitor data should come automatically via MONITOR_LIST event');
    _log('No explicit request needed - waiting for automatic events after authentication...');

    // According to the uptime-kuma-api source, after authentication the server
    // automatically sends MONITOR_LIST and other events. No explicit request needed.
  }
  
  void _processMonitorList(dynamic data) {
    _log('Processing monitor list from MONITOR_LIST event: $data');

    // Expect data format: [String: [String: Any]] matching Swift implementation
    if (data is Map<String, dynamic>) {
      final Map<int, Monitor> newMonitors = {};

      _log('Processing monitor dictionary with ${data.length} entries');

      for (final entry in data.entries) {
        final monitorIdStr = entry.key;
        final monitorInfo = entry.value;

        if (monitorInfo is Map<String, dynamic>) {
          final monitorId = int.tryParse(monitorIdStr);
          if (monitorId != null) {
            try {
              final monitor = Monitor.fromJson({
                'id': monitorId,
                'name': monitorInfo['name'] ?? 'Unknown',
                'url': monitorInfo['url'],
                'type': monitorInfo['type'] ?? 'http',
                'interval': monitorInfo['interval'] ?? 60,
                'status': monitorInfo['active'] as bool? ?? false,
                'active': monitorInfo['active'] as bool? ?? false,
                'parent': monitorInfo['parent'],
                'childrenIDs': monitorInfo['childrenIDs'],
              });

              newMonitors[monitorId] = monitor;
              _log('Created monitor: ${monitor.name} (ID: $monitorId, parent: ${monitor.parent?.toString() ?? "nil"})');
            } catch (e) {
              _log('Error parsing monitor $monitorId: $e');
            }
          }
        }
      }

      _monitors.clear();
      _monitors.addAll(newMonitors);
      _organizeMonitorsIntoGroups();
      _updateLastUpdate();

      _log('Updated monitors list with ${_monitors.length} monitors');
      notifyListeners();
    } else {
      _log('Unexpected monitor data format: ${data.runtimeType}');
      _log('Data received: $data');
    }
  }
  
  void _processHeartbeat(dynamic data) {
    if (data is Map<String, dynamic>) {
      try {
        final heartbeat = Heartbeat.fromJson(data);
        
        if (!_heartbeats.containsKey(heartbeat.monitorId)) {
          _heartbeats[heartbeat.monitorId] = [];
        }
        
        _heartbeats[heartbeat.monitorId]!.insert(0, heartbeat);
        
        // Keep only last 50 heartbeats
        if (_heartbeats[heartbeat.monitorId]!.length > 50) {
          _heartbeats[heartbeat.monitorId] = _heartbeats[heartbeat.monitorId]!.take(50).toList();
        }
        
        _checkIndividualMonitorNotifications(heartbeat.monitorId);
        _updateLastUpdate();
        notifyListeners();
      } catch (e) {
        _log('Error parsing heartbeat: $e');
      }
    }
  }
  
  void _processHeartbeatList(dynamic data) {
    _log('Processing heartbeat list: $data');
    // Process historical heartbeat data
  }
  
  void _processUptime(dynamic data) {
    if (data is Map<String, dynamic>) {
      final monitorId = data['id'] as int?;
      final uptime = data['uptime'] as double?;
      
      if (monitorId != null && uptime != null) {
        _uptimes[monitorId] = uptime * 100; // Convert to percentage
        notifyListeners();
      }
    }
  }
  
  void _processAvgPing(dynamic data) {
    _log('Processing average ping: $data');
    // Handle average ping data
  }

  void _processDashboard(dynamic data) {
    _log('Processing dashboard data: $data');
    // Dashboard data might contain monitor information
    if (data is Map<String, dynamic>) {
      if (data.containsKey('monitors')) {
        _processMonitorList(data['monitors']);
      } else if (data.containsKey('monitorList')) {
        _processMonitorList(data['monitorList']);
      } else {
        // Try processing the entire data as monitor list
        _processMonitorList(data);
      }
    }
  }
  
  void _organizeMonitorsIntoGroups() {
    final Map<int, _GroupData> tempGroups = {};
    final List<Monitor> tempStandalone = [];
    
    // First pass: identify groups (parent monitors)
    for (final monitor in _monitors.values) {
      if (monitor.parent == null) {
        tempGroups[monitor.id] = _GroupData(monitor: monitor, children: []);
      }
    }
    
    // Second pass: assign children to groups
    for (final monitor in _monitors.values) {
      if (monitor.parent != null) {
        final parentId = monitor.parent!;
        if (tempGroups.containsKey(parentId)) {
          tempGroups[parentId]!.children.add(monitor);
        } else {
          tempStandalone.add(monitor);
        }
      }
    }
    
    // Convert to final group structure
    final List<MonitorGroup> finalGroups = [];
    for (final entry in tempGroups.entries) {
      final groupId = entry.key;
      final groupData = entry.value;
      
      if (groupData.children.isEmpty) {
        // Group with no children, treat as standalone
        tempStandalone.add(groupData.monitor);
      } else {
        // Create group with children
        final onlineCount = groupData.children
            .where((child) => getMonitorStatus(child.id) == MonitorStatus.up)
            .length;
        
        final group = MonitorGroup(
          id: groupId,
          name: groupData.monitor.name,
          children: groupData.children,
          onlineCount: onlineCount,
          totalCount: groupData.children.length,
        );
        finalGroups.add(group);
      }
    }
    
    _groups = finalGroups;
    _standaloneMonitors = tempStandalone;
    
    _log('Organized monitors: ${finalGroups.length} groups, ${tempStandalone.length} standalone');
  }
  
  void _checkIndividualMonitorNotifications(int monitorId) {
    if (!_settings.notificationsEnabled) return;
    
    final currentStatus = getMonitorStatus(monitorId);
    final previousStatus = _previousStatuses[monitorId] ?? MonitorStatus.unknown;
    
    if (currentStatus != previousStatus && previousStatus != MonitorStatus.unknown) {
      final monitor = _monitors[monitorId];
      if (monitor != null) {
        switch (currentStatus) {
          case MonitorStatus.down:
            if (_settings.notifyOnDown) {
              if (_notificationService != null) {
                _notificationService!.showMonitorDownNotification(
                  monitorName: monitor.name,
                  url: monitor.url,
                );
              } else {
                _sendNotification(
                  'Monitor Down: ${monitor.name}',
                  'Monitor ${monitor.name} is no longer responding',
                  payload: 'monitor_down:${monitor.name}',
                );
              }
            }
            break;
          case MonitorStatus.up:
            if (previousStatus == MonitorStatus.down && _settings.notifyOnUp) {
              if (_notificationService != null) {
                _notificationService!.showMonitorUpNotification(
                  monitorName: monitor.name,
                  url: monitor.url,
                );
              } else {
                _sendNotification(
                  'Monitor Recovered: ${monitor.name}',
                  'Monitor ${monitor.name} is back online',
                  payload: 'monitor_up:${monitor.name}',
                );
              }
            }
            break;
          case MonitorStatus.pending:
            if (_settings.notifyOnPending && _notificationService != null) {
              _notificationService!.showMonitorPendingNotification(
                monitorName: monitor.name,
                url: monitor.url,
              );
            }
            break;
          default:
            break;
        }
      }
    }
    
    _previousStatuses[monitorId] = currentStatus;
  }
  
  void setNotificationService(NotificationService notificationService) {
    _notificationService = notificationService;
  }

  void _sendNotification(String title, String body, {String? payload}) {
    _log('Notification: $title - $body');
    
    if (_notificationService != null) {
      _notificationService!.showNotification(
        title: title,
        body: body,
        payload: payload,
      );
    }
  }
  
  MonitorStatus getMonitorStatus(int monitorId) {
    final beats = _heartbeats[monitorId];
    if (beats != null && beats.isNotEmpty) {
      return MonitorStatus.fromHeartbeatStatus(beats.first.status);
    }
    
    // Fall back to monitor active status
    final monitor = _monitors[monitorId];
    if (monitor != null && monitor.active) {
      return MonitorStatus.up;
    }
    
    return MonitorStatus.unknown;
  }
  
  double? getMonitorResponseTime(int monitorId) {
    final beats = _heartbeats[monitorId];
    if (beats != null && beats.isNotEmpty) {
      return beats.first.ping;
    }
    return null;
  }
  
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setConnected(false);
  }
  
  void fetchData() {
    if (_isConnected) {
      _requestMonitorList();
    } else {
      connect();
    }
  }
  
  // Helper methods
  void _setConnected(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      notifyListeners();
    }
  }
  
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  void _setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }
  
  void _updateLastUpdate() {
    _lastUpdate = DateTime.now();
  }
  
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('UptimeKumaService: $message');
    }
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

class _GroupData {
  final Monitor monitor;
  final List<Monitor> children;
  
  _GroupData({required this.monitor, required this.children});
}