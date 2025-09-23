import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsService extends ChangeNotifier {
  static const String _settingsKey = 'uptime_kuma_settings';
  
  UptimeKumaSettings _settings = const UptimeKumaSettings();
  bool _isLoaded = false;
  
  UptimeKumaSettings get settings => _settings;
  bool get isLoaded => _isLoaded;
  
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      debugPrint('SettingsService: Loading settings...');
      debugPrint('SettingsService: settingsJson = $settingsJson');

      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = UptimeKumaSettings.fromJson(settingsMap);
        debugPrint('SettingsService: Loaded settings from storage');
      } else {
        debugPrint('SettingsService: No settings found, using defaults');
      }

      debugPrint('SettingsService: serverUrl = ${_settings.serverUrl}');
      debugPrint('SettingsService: username = ${_settings.username}');
      debugPrint('SettingsService: password = ${_settings.password.isEmpty ? '(empty)' : '(set)'}');
      debugPrint('SettingsService: isConfigured = ${_settings.isConfigured}');

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }
  
  Future<void> saveSettings(UptimeKumaSettings newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(newSettings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
      
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving settings: $e');
      rethrow;
    }
  }
  
  Future<void> updateSettings(UptimeKumaSettings Function(UptimeKumaSettings) update) async {
    final newSettings = update(_settings);
    await saveSettings(newSettings);
  }
  
  Future<void> resetSettings() async {
    await saveSettings(const UptimeKumaSettings());
  }
}