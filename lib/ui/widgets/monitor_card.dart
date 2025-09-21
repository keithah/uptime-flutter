import 'package:flutter/material.dart';
import '../../models/monitor.dart';
import '../../models/monitor_status.dart';

class MonitorCard extends StatelessWidget {
  const MonitorCard({
    super.key,
    required this.monitor,
    required this.status,
    this.uptime,
    this.responseTime,
    this.showResponseTime = true,
    this.isCompact = false,
    this.isHighlighted = false,
    this.onTap,
  });

  final Monitor monitor;
  final MonitorStatus status;
  final double? uptime;
  final double? responseTime;
  final bool showResponseTime;
  final bool isCompact;
  final bool isHighlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isHighlighted ? 4 : null,
      color: isHighlighted 
          ? status.color.withOpacity(0.1)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          child: isCompact ? _buildCompactLayout(theme) : _buildNormalLayout(theme),
        ),
      ),
    );
  }

  Widget _buildNormalLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monitor.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (monitor.url != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      monitor.url!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              status.displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: status.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        if (uptime != null || (showResponseTime && responseTime != null)) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (uptime != null) ...[
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${uptime!.toStringAsFixed(1)}% uptime',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              
              if (uptime != null && showResponseTime && responseTime != null) ...[
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 12,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 16),
              ],
              
              if (showResponseTime && responseTime != null) ...[
                Icon(
                  Icons.timer,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${responseTime!.toInt()}ms',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCompactLayout(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            monitor.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        if (uptime != null) ...[
          Text(
            '${uptime!.toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
        ],
        
        if (showResponseTime && responseTime != null) ...[
          Text(
            '${responseTime!.toInt()}ms',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
        ],
        
        Text(
          status.icon,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}