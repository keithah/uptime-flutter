import 'package:uptime_flutter/models/monitor.dart';
import 'package:uptime_flutter/models/monitor_status.dart';

class MonitorGroup {
  final int id;
  final String name;
  final List<Monitor> children;
  final int onlineCount;
  final int totalCount;

  const MonitorGroup({
    required this.id,
    required this.name,
    required this.children,
    required this.onlineCount,
    required this.totalCount,
  });

  String get statusIcon {
    if (totalCount == 0) return '❓';
    if (onlineCount == totalCount) return '🟢';
    if (onlineCount > 0) return '⚠️';
    return '❗️';
  }

  MonitorStatus get overallStatus {
    if (totalCount == 0) return MonitorStatus.unknown;
    if (onlineCount == totalCount) return MonitorStatus.up;
    if (onlineCount == 0) return MonitorStatus.down;
    return MonitorStatus.pending;
  }

  double get uptimePercentage {
    if (totalCount == 0) return 0.0;
    return (onlineCount / totalCount) * 100;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonitorGroup && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MonitorGroup{id: $id, name: $name, online: $onlineCount/$totalCount}';
}