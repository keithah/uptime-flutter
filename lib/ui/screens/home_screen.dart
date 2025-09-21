import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/uptime_kuma_service.dart';
import '../widgets/monitor_card.dart';
import '../widgets/monitor_group_card.dart';
import '../widgets/status_header.dart';
import '../widgets/connection_status_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uptime Kuma Monitor'),
        actions: [
          Consumer<UptimeKumaService>(
            builder: (context, service, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ConnectionStatusIndicator(),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: service.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    onPressed: service.isLoading ? null : () => service.fetchData(),
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
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

          return RefreshIndicator(
            onRefresh: () async => service.fetchData(),
            child: CustomScrollView(
              slivers: [
                // Status Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: StatusHeader(
                      overallStatus: service.overallStatus,
                      totalMonitors: service.totalMonitors,
                      onlineMonitors: service.onlineMonitors,
                      lastUpdate: service.lastUpdate,
                    ),
                  ),
                ),

                // Failed Monitors Section
                if (service.failedMonitors.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Failed Monitors (${service.failedMonitors.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final monitor = service.failedMonitors[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: MonitorCard(
                            monitor: monitor,
                            status: service.getMonitorStatus(monitor.id),
                            uptime: service.uptimes[monitor.id],
                            responseTime: service.getMonitorResponseTime(monitor.id),
                            showResponseTime: service.settings.showResponseTime,
                            isCompact: service.settings.compactMode,
                            isHighlighted: true,
                          ),
                        );
                      },
                      childCount: service.failedMonitors.length,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Divider(),
                    ),
                  ),
                ],

                // Monitor Groups
                if (service.groups.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Monitor Groups',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final group = service.groups[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: MonitorGroupCard(
                            group: group,
                            service: service,
                          ),
                        );
                      },
                      childCount: service.groups.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],

                // Standalone Monitors
                if (service.standaloneMonitors.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Monitors',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final monitor = service.standaloneMonitors[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: MonitorCard(
                            monitor: monitor,
                            status: service.getMonitorStatus(monitor.id),
                            uptime: service.uptimes[monitor.id],
                            responseTime: service.getMonitorResponseTime(monitor.id),
                            showResponseTime: service.settings.showResponseTime,
                            isCompact: service.settings.compactMode,
                          ),
                        );
                      },
                      childCount: service.standaloneMonitors.length,
                    ),
                  ),
                ],

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          );
        },
      ),
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
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
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
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Monitors',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No monitors are configured in your Uptime Kuma instance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}