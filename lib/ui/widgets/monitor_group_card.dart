import 'package:flutter/material.dart';
import '../../models/monitor_group.dart';
import '../../services/uptime_kuma_service.dart';
import 'monitor_card.dart';

class MonitorGroupCard extends StatefulWidget {
  const MonitorGroupCard({
    super.key,
    required this.group,
    required this.service,
  });

  final MonitorGroup group;
  final UptimeKumaService service;

  @override
  State<MonitorGroupCard> createState() => _MonitorGroupCardState();
}

class _MonitorGroupCardState extends State<MonitorGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.group.overallStatus.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.group.onlineCount}/${widget.group.totalCount} monitors online',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.group.uptimePercentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          
          // Progress indicator
          LinearProgressIndicator(
            value: widget.group.totalCount > 0 
                ? widget.group.onlineCount / widget.group.totalCount 
                : 0.0,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.group.overallStatus.color,
            ),
          ),
          
          // Expanded content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: widget.group.children.map((monitor) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: MonitorCard(
                      monitor: monitor,
                      status: widget.service.getMonitorStatus(monitor.id),
                      uptime: widget.service.uptimes[monitor.id],
                      responseTime: widget.service.getMonitorResponseTime(monitor.id),
                      showResponseTime: widget.service.settings.showResponseTime,
                      isCompact: true,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}