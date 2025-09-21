import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/settings_service.dart';
import '../../services/uptime_kuma_service.dart';
import '../../services/window_manager_service.dart';
import '../../services/notification_service.dart';
import '../../models/settings.dart';
import '../../utils/platform_helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.isFirstTime = false,
  });

  final bool isFirstTime;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _notificationsEnabled = false;
  bool _notifyOnDown = true;
  bool _notifyOnUp = true;
  bool _notifyOnPending = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  NotificationPriority _notificationPriority = NotificationPriority.normal;
  bool _showResponseTime = true;
  bool _compactMode = false;
  double _refreshInterval = 30.0;
  
  bool _isTestingConnection = false;
  String? _connectionTestResult;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showNotificationHistory() {
    final notificationService = NotificationService();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: notificationService.notificationHistory.isEmpty
              ? const Center(
                  child: Text('No notifications yet'),
                )
              : ListView.builder(
                  itemCount: notificationService.notificationHistory.length,
                  itemBuilder: (context, index) {
                    final notification = notificationService.notificationHistory[index];
                    return ListTile(
                      title: Text(notification.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.body),
                          const SizedBox(height: 4),
                          Text(
                            '${notification.timestamp.toString().substring(0, 19)} - ${notification.priority.name}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      leading: CircleAvatar(
                        child: Icon(_getNotificationIcon(notification)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              notificationService.clearNotificationHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification history cleared')),
              );
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationRecord notification) {
    if (notification.payload?.startsWith('monitor_down') == true) {
      return Icons.error;
    } else if (notification.payload?.startsWith('monitor_up') == true) {
      return Icons.check_circle;
    } else if (notification.payload?.startsWith('monitor_pending') == true) {
      return Icons.warning;
    }
    return Icons.notifications;
  }

  Future<void> _sendTestNotification() async {
    final notificationService = NotificationService();
    
    await notificationService.showNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Uptime Kuma Flutter Client',
      priority: _notificationPriority,
      playSound: _soundEnabled,
      enableVibration: _vibrationEnabled,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent')),
      );
    }
  }

  void _loadCurrentSettings() {
    final settingsService = context.read<SettingsService>();
    final settings = settingsService.settings;
    
    _serverUrlController.text = settings.serverUrl;
    _usernameController.text = settings.username;
    _passwordController.text = settings.password;
    _notificationsEnabled = settings.notificationsEnabled;
    _notifyOnDown = settings.notifyOnDown;
    _notifyOnUp = settings.notifyOnUp;
    _notifyOnPending = settings.notifyOnPending;
    _soundEnabled = settings.soundEnabled;
    _vibrationEnabled = settings.vibrationEnabled;
    _notificationPriority = settings.notificationPriority;
    _showResponseTime = settings.showResponseTime;
    _compactMode = settings.compactMode;
    _refreshInterval = settings.refreshInterval;
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    try {
      // TODO: Implement actual connection test
      // For now, just simulate a test
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _connectionTestResult = 'Connection successful!';
      });
    } catch (e) {
      setState(() {
        _connectionTestResult = 'Connection failed: $e';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final newSettings = UptimeKumaSettings(
      serverUrl: _serverUrlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      refreshInterval: _refreshInterval,
      notificationsEnabled: _notificationsEnabled,
      notifyOnDown: _notifyOnDown,
      notifyOnUp: _notifyOnUp,
      notifyOnPending: _notifyOnPending,
      soundEnabled: _soundEnabled,
      vibrationEnabled: _vibrationEnabled,
      notificationPriority: _notificationPriority,
      showResponseTime: _showResponseTime,
      compactMode: _compactMode,
    );

    try {
      final settingsService = context.read<SettingsService>();
      await settingsService.saveSettings(newSettings);
      
      // Update notification service settings
      final notificationService = NotificationService();
      notificationService.setNotificationsEnabled(newSettings.notificationsEnabled);
      notificationService.setNotifyOnDown(newSettings.notifyOnDown);
      notificationService.setNotifyOnUp(newSettings.notifyOnUp);
      notificationService.setNotifyOnPending(newSettings.notifyOnPending);
      notificationService.setSoundEnabled(newSettings.soundEnabled);
      notificationService.setVibrationEnabled(newSettings.vibrationEnabled);
      notificationService.setPriority(newSettings.notificationPriority);

      if (mounted) {
        final uptimeService = context.read<UptimeKumaService>();
        uptimeService.updateSettings(newSettings);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.isFirstTime) {
          // Navigate to main app after first-time setup
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstTime ? 'Setup' : 'Settings'),
        automaticallyImplyLeading: !widget.isFirstTime,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (widget.isFirstTime) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.monitor_heart,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to Uptime Kuma Monitor',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configure your Uptime Kuma server connection to get started.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Server Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.dns,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Server Configuration',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _serverUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'http://localhost:3001',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Server URL is required';
                        }
                        final uri = Uri.tryParse(value.trim());
        if (uri == null || !uri.hasAbsolutePath) {
                          return 'Invalid URL format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isTestingConnection ? null : _testConnection,
                            icon: _isTestingConnection
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.wifi_tethering),
                            label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_connectionTestResult != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _connectionTestResult!.contains('successful')
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          border: Border.all(
                            color: _connectionTestResult!.contains('successful')
                                ? Colors.green
                                : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _connectionTestResult!,
                          style: TextStyle(
                            color: _connectionTestResult!.contains('successful')
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Display Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.display_settings,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Display Options',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Text('Refresh Interval: ${_refreshInterval.toInt()}s'),
                        ),
                      ],
                    ),
                    Slider(
                      value: _refreshInterval,
                      min: 10,
                      max: 300,
                      divisions: 29,
                      onChanged: (value) {
                        setState(() {
                          _refreshInterval = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Compact Mode'),
                      subtitle: const Text('Use smaller cards for monitors'),
                      value: _compactMode,
                      onChanged: (value) {
                        setState(() {
                          _compactMode = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Show Response Time'),
                      subtitle: const Text('Display ping times for monitors'),
                      value: _showResponseTime,
                      onChanged: (value) {
                        setState(() {
                          _showResponseTime = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notifications',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Receive alerts for monitor status changes'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Notify on Monitor Down'),
                      subtitle: const Text('Alert when monitors go offline'),
                      value: _notifyOnDown,
                      onChanged: _notificationsEnabled ? (value) {
                        setState(() {
                          _notifyOnDown = value;
                        });
                      } : null,
                    ),
                    
                    SwitchListTile(
                      title: const Text('Notify on Monitor Recovery'),
                      subtitle: const Text('Alert when monitors come back online'),
                      value: _notifyOnUp,
                      onChanged: _notificationsEnabled ? (value) {
                        setState(() {
                          _notifyOnUp = value;
                        });
                      } : null,
                    ),
                    
                    SwitchListTile(
                      title: const Text('Notify on Monitor Warning'),
                      subtitle: const Text('Alert when monitors have issues'),
                      value: _notifyOnPending,
                      onChanged: _notificationsEnabled ? (value) {
                        setState(() {
                          _notifyOnPending = value;
                        });
                      } : null,
                    ),
                    
                    const Divider(),
                    
                    SwitchListTile(
                      title: const Text('Sound'),
                      subtitle: const Text('Play notification sound'),
                      value: _soundEnabled,
                      onChanged: _notificationsEnabled ? (value) {
                        setState(() {
                          _soundEnabled = value;
                        });
                      } : null,
                    ),
                    
                    SwitchListTile(
                      title: const Text('Vibration'),
                      subtitle: const Text('Vibrate device for notifications (mobile)'),
                      value: _vibrationEnabled,
                      onChanged: _notificationsEnabled ? (value) {
                        setState(() {
                          _vibrationEnabled = value;
                        });
                      } : null,
                    ),
                    
                    ListTile(
                      title: const Text('Priority'),
                      subtitle: Text('Default notification priority: ${_notificationPriority.name}'),
                      trailing: DropdownButton<NotificationPriority>(
                        value: _notificationPriority,
                        onChanged: _notificationsEnabled ? (NotificationPriority? value) {
                          if (value != null) {
                            setState(() {
                              _notificationPriority = value;
                            });
                          }
                        } : null,
                        items: NotificationPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority.name.toUpperCase()),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const Divider(),
                    
                    ListTile(
                      title: const Text('Notification History'),
                      subtitle: const Text('View recent notifications'),
                      trailing: const Icon(Icons.history),
                      onTap: _notificationsEnabled ? () => _showNotificationHistory() : null,
                    ),
                    
                    ListTile(
                      title: const Text('Test Notification'),
                      subtitle: const Text('Send a test notification'),
                      trailing: const Icon(Icons.send),
                      onTap: _notificationsEnabled ? () => _sendTestNotification() : null,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Desktop Settings (only show on desktop platforms)
            if (PlatformHelpers.isDesktop) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.desktop_windows,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Desktop Behavior',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Consumer<WindowManagerService>(
                        builder: (context, windowService, child) {
                          return Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Minimize to System Tray'),
                                subtitle: const Text('Hide window to tray when minimized'),
                                value: windowService.minimizeToTray,
                                onChanged: (value) {
                                  windowService.setMinimizeToTray(value);
                                },
                              ),
                              
                              SwitchListTile(
                                title: const Text('Close to System Tray'),
                                subtitle: const Text('Hide to tray instead of closing'),
                                value: windowService.closeToTray,
                                onChanged: (value) {
                                  windowService.setCloseToTray(value);
                                },
                              ),
                              
                              SwitchListTile(
                                title: const Text('Start Minimized'),
                                subtitle: const Text('Start application minimized to tray'),
                                value: windowService.startMinimized,
                                onChanged: (value) {
                                  windowService.setStartMinimized(value);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 8),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.isFirstTime ? 'Complete Setup' : 'Save Settings'),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}