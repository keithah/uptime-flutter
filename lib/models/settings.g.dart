// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UptimeKumaSettings _$UptimeKumaSettingsFromJson(Map<String, dynamic> json) =>
    UptimeKumaSettings(
      serverUrl: json['serverUrl'] as String? ?? 'http://localhost:3001',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      refreshInterval: (json['refreshInterval'] as num?)?.toDouble() ?? 30.0,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      notifyOnDown: json['notifyOnDown'] as bool? ?? true,
      notifyOnUp: json['notifyOnUp'] as bool? ?? true,
      notifyOnPending: json['notifyOnPending'] as bool? ?? false,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      notificationPriority: $enumDecodeNullable(
              _$NotificationPriorityEnumMap, json['notificationPriority']) ??
          NotificationPriority.normal,
      showResponseTime: json['showResponseTime'] as bool? ?? true,
      compactMode: json['compactMode'] as bool? ?? false,
    );

Map<String, dynamic> _$UptimeKumaSettingsToJson(UptimeKumaSettings instance) =>
    <String, dynamic>{
      'serverUrl': instance.serverUrl,
      'username': instance.username,
      'password': instance.password,
      'refreshInterval': instance.refreshInterval,
      'notificationsEnabled': instance.notificationsEnabled,
      'notifyOnDown': instance.notifyOnDown,
      'notifyOnUp': instance.notifyOnUp,
      'notifyOnPending': instance.notifyOnPending,
      'soundEnabled': instance.soundEnabled,
      'vibrationEnabled': instance.vibrationEnabled,
      'notificationPriority':
          _$NotificationPriorityEnumMap[instance.notificationPriority]!,
      'showResponseTime': instance.showResponseTime,
      'compactMode': instance.compactMode,
    };

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.normal: 'normal',
  NotificationPriority.high: 'high',
  NotificationPriority.max: 'max',
};
