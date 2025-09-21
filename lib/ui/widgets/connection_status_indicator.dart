import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/uptime_kuma_service.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UptimeKumaService>(
      builder: (context, service, child) {
        final theme = Theme.of(context);
        
        Color statusColor;
        IconData statusIcon;
        String statusText;
        String tooltipText;
        
        if (service.isConnected) {
          statusColor = Colors.green;
          statusIcon = Icons.cloud_done;
          statusText = 'Connected';
          tooltipText = 'Connected to Uptime Kuma server';
        } else if (service.isLoading) {
          statusColor = Colors.orange;
          statusIcon = Icons.cloud_sync;
          statusText = 'Connecting';
          tooltipText = 'Connecting to server...';
        } else {
          statusColor = Colors.red;
          statusIcon = Icons.cloud_off;
          statusText = 'Offline';
          tooltipText = service.errorMessage ?? 'Not connected to server';
        }
        
        return Tooltip(
          message: tooltipText,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (service.isLoading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ] else ...[
                Icon(
                  statusIcon,
                  size: 16,
                  color: statusColor,
                ),
              ],
              const SizedBox(width: 6),
              Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}