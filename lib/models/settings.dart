import 'package:json_annotation/json_annotation.dart';
import '../services/notification_service.dart';

part 'settings.g.dart';

@JsonSerializable()
class UptimeKumaSettings {
  final String serverUrl;
  final String username;
  final String password;
  final double refreshInterval;
  final bool notificationsEnabled;
  final bool notifyOnDown;
  final bool notifyOnUp;
  final bool notifyOnPending;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final NotificationPriority notificationPriority;
  final bool showResponseTime;
  final bool compactMode;

  const UptimeKumaSettings({
    this.serverUrl = 'http://localhost:3001',
    this.username = '',
    this.password = '',
    this.refreshInterval = 30.0,
    this.notificationsEnabled = false,
    this.notifyOnDown = true,
    this.notifyOnUp = true,
    this.notifyOnPending = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.notificationPriority = NotificationPriority.normal,
    this.showResponseTime = true,
    this.compactMode = false,
  });

  factory UptimeKumaSettings.fromJson(Map<String, dynamic> json) =>
      _$UptimeKumaSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UptimeKumaSettingsToJson(this);

  UptimeKumaSettings copyWith({
    String? serverUrl,
    String? username,
    String? password,
    double? refreshInterval,
    bool? notificationsEnabled,
    bool? notifyOnDown,
    bool? notifyOnUp,
    bool? notifyOnPending,
    bool? soundEnabled,
    bool? vibrationEnabled,
    NotificationPriority? notificationPriority,
    bool? showResponseTime,
    bool? compactMode,
  }) {
    return UptimeKumaSettings(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyOnDown: notifyOnDown ?? this.notifyOnDown,
      notifyOnUp: notifyOnUp ?? this.notifyOnUp,
      notifyOnPending: notifyOnPending ?? this.notifyOnPending,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationPriority: notificationPriority ?? this.notificationPriority,
      showResponseTime: showResponseTime ?? this.showResponseTime,
      compactMode: compactMode ?? this.compactMode,
    );
  }

  bool get isConfigured =>
      serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
}