import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/uptime_kuma_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UptimeKumaService>(
        builder: (context, service, child) {
          if (service.isLoading && service.monitors.isEmpty) {
            return const _LoadingView();
          }

          if (service.errorMessage != null) {
            return _ErrorView(
              message: service.errorMessage!,
              onRetry: () => service.fetchData(),
            );
          }

          if (service.monitors.isEmpty) {
            return const _EmptyStateView();
          }

          return _CleanMonitorGroupList(service: service);
        },
      ),
    );
  }
}

class _CleanMonitorGroupList extends StatelessWidget {
  const _CleanMonitorGroupList({required this.service});

  final UptimeKumaService service;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      children: [
        // Show groups
        if (service.groups.isNotEmpty) ...[
          ...service.groups.map((group) {
            final groupMonitors = service.monitors.values.where((m) => m.parent == group.id).toList();
            final onlineCount = groupMonitors.where((m) => service.getMonitorStatus(m.id) == 'up').length;
            final totalCount = groupMonitors.length;
            final allOnline = onlineCount == totalCount;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 8.0),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: allOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Group name and count
                    Expanded(
                      child: Text(
                        '${group.name} $onlineCount/$totalCount',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],

        // Show standalone monitors
        if (service.standaloneMonitors.isNotEmpty) ...[
          ...service.standaloneMonitors.map((monitor) {
            final isOnline = service.getMonitorStatus(monitor.id) == 'up';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 8.0),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Monitor name
                    Expanded(
                      child: Text(
                        monitor.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading monitors...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Monitors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No monitors found.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}