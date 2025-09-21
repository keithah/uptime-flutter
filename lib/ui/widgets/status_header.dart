import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/monitor_status.dart';

class StatusHeader extends StatelessWidget {
  const StatusHeader({
    super.key,
    required this.overallStatus,
    required this.totalMonitors,
    required this.onlineMonitors,
    this.lastUpdate,
  });

  final MonitorStatus overallStatus;
  final int totalMonitors;
  final int onlineMonitors;
  final DateTime? lastUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offlineMonitors = totalMonitors - onlineMonitors;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: overallStatus.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStatusTitle(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    title: 'Online',
                    value: onlineMonitors.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.error_outline,
                    color: Colors.red,
                    title: 'Offline',
                    value: offlineMonitors.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.monitor_heart,
                    color: theme.colorScheme.primary,
                    title: 'Total',
                    value: totalMonitors.toString(),
                  ),
                ),
              ],
            ),
            
            if (lastUpdate != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last updated: ${DateFormat('MMM d, y h:mm a').format(lastUpdate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusTitle() {
    if (totalMonitors == 0) {
      return 'No Monitors';
    }
    
    switch (overallStatus) {
      case MonitorStatus.up:
        return 'All Systems Operational';
      case MonitorStatus.down:
        return 'System Issues Detected';
      case MonitorStatus.pending:
        return 'Partial System Issues';
      case MonitorStatus.paused:
        return 'Monitoring Paused';
      case MonitorStatus.unknown:
        return 'Status Unknown';
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}