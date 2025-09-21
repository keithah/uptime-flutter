import 'package:flutter/material.dart';

enum MonitorStatus {
  up,
  down,
  pending,
  paused,
  unknown;

  Color get color {
    switch (this) {
      case MonitorStatus.up:
        return Colors.green;
      case MonitorStatus.down:
        return Colors.red;
      case MonitorStatus.pending:
        return Colors.orange;
      case MonitorStatus.paused:
        return Colors.grey;
      case MonitorStatus.unknown:
        return Colors.amber;
    }
  }

  String get icon {
    switch (this) {
      case MonitorStatus.up:
        return '✅';
      case MonitorStatus.down:
        return '❌';
      case MonitorStatus.pending:
        return '⏳';
      case MonitorStatus.paused:
        return '⏸';
      case MonitorStatus.unknown:
        return '❓';
    }
  }

  String get displayName {
    switch (this) {
      case MonitorStatus.up:
        return 'Up';
      case MonitorStatus.down:
        return 'Down';
      case MonitorStatus.pending:
        return 'Pending';
      case MonitorStatus.paused:
        return 'Paused';
      case MonitorStatus.unknown:
        return 'Unknown';
    }
  }

  static MonitorStatus fromHeartbeatStatus(int status) {
    switch (status) {
      case 0:
        return MonitorStatus.down;
      case 1:
        return MonitorStatus.up;
      case 2:
        return MonitorStatus.pending;
      case 3:
        return MonitorStatus.paused;
      default:
        return MonitorStatus.unknown;
    }
  }
}