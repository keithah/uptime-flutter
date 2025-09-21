import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'services/uptime_kuma_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'services/system_tray_service.dart';
import 'services/window_manager_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize platform-specific features
  await _initializePlatformFeatures();
  
  // Initialize services
  await NotificationService().initialize();
  
  runApp(const UptimeKumaApp());
}

Future<void> _initializePlatformFeatures() async {
  // Desktop window management
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
    // WindowManagerService will handle the detailed window configuration
    await WindowManagerService().initialize();
  }
}

class UptimeKumaApp extends StatelessWidget {
  const UptimeKumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProvider(create: (_) => UptimeKumaService()),
        ChangeNotifierProvider(create: (_) => SystemTrayService()),
        ChangeNotifierProvider(create: (_) => WindowManagerService()),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settingsService, child) {
          return MaterialApp(
            title: 'Uptime Kuma Monitor',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            themeMode: ThemeMode.system,
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    
    final settingsService = context.read<SettingsService>();
    await settingsService.loadSettings();
    
    if (mounted) {
      // Initialize system tray on desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final systemTrayService = context.read<SystemTrayService>();
        final uptimeService = context.read<UptimeKumaService>();
        final notificationService = NotificationService();
        
        // Use Future.microtask to avoid BuildContext across async gaps
        Future.microtask(() async {
          await systemTrayService.initialize(
            uptimeService: uptimeService,
            notificationService: notificationService,
          );
        });
      }
      
      // Configure uptime service if settings are available
      if (settingsService.settings.isConfigured) {
        final uptimeService = context.read<UptimeKumaService>();
        final notificationService = NotificationService();
        
        // Connect notification service to uptime service
        uptimeService.setNotificationService(notificationService);
        uptimeService.updateSettings(settingsService.settings);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        if (!settingsService.isLoaded) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (!settingsService.settings.isConfigured) {
          return const SettingsScreen(isFirstTime: true);
        }
        
        return const MainApp();
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const HomeScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // For desktop, show a single window with navigation rail
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      );
    }
    
    // For mobile, show bottom navigation
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
