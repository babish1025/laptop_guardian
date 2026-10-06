/// Laptop Guardian — API Configuration
///
/// Supports runtime URL changes so you can switch between local LAN
/// testing and Cloud HTTPS (Railway/Render) without recompiling.
library api_config;

import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  /// Default compiled base URL.
  /// Set at build time: flutter build apk --dart-define=API_BASE_URL=https://YOUR-BACKEND-DOMAIN
  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'https://laptop-guardian.up.railway.app',
    ),
  );

  /// Safe local development defaults
  static const String defaultLocalDevUrl = 'http://10.0.2.2:5000';

  static String? _customUrl;

  /// Active base URL (custom URL if set, otherwise compiled default)
  static String get baseUrl {
    final active = _customUrl ?? _defaultUrl;
    return active.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Whether current active endpoint is using HTTPS
  static bool get isHttps => baseUrl.startsWith('https://');

  /// Whether current active endpoint is a local dev address
  static bool get isLocalDev =>
      baseUrl.contains('127.0.0.1') ||
      baseUrl.contains('localhost') ||
      baseUrl.contains('10.0.2.2') ||
      baseUrl.startsWith('http://192.168.') ||
      baseUrl.startsWith('http://10.') ||
      baseUrl.startsWith('http://172.');

  /// Load persisted custom URL if user changed it in Settings
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('custom_base_url');
      if (saved != null && saved.trim().isNotEmpty) {
        _customUrl = saved.trim().replaceAll(RegExp(r'/+$'), '');
      }
    } catch (_) {}
  }

  /// Update and persist custom base URL
  static Future<bool> setBaseUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isEmpty) return false;
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      return false;
    }

    _customUrl = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_base_url', clean);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reset to default compiled URL
  static Future<void> resetBaseUrl() async {
    _customUrl = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('custom_base_url');
    } catch (_) {}
  }

  // API timeout
  static const Duration timeout = Duration(seconds: 15);

  // Polling interval fallback for notifications (when FCM is initializing or offline)
  static const Duration notificationPollInterval = Duration(seconds: 30);

  // How often the dashboard auto-refreshes device status
  static const Duration dashboardRefreshInterval = Duration(seconds: 20);
}
