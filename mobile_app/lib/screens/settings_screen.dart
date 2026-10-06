import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/fcm_service.dart';
import '../widgets/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;
  final _urlController = TextEditingController();
  bool _isTestingConnection = false;
  String? _connectionTestResult;
  bool? _connectionTestSuccess;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiConfig.baseUrl;
    _loadUser();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final storage = context.read<StorageService>();
    final user = await storage.getUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
      _connectionTestSuccess = null;
    });

    final stopwatch = Stopwatch()..start();
    // Temporarily set to test
    await ApiConfig.setBaseUrl(url);

    try {
      final api = context.read<ApiService>();
      final res = await api.get('/api/health');
      stopwatch.stop();

      if (!mounted) return;

      if (res['status'] == 'healthy' || res['status'] == 'ok') {
        setState(() {
          _connectionTestSuccess = true;
          _connectionTestResult = 'Connected! Latency: ${stopwatch.elapsedMilliseconds} ms';
        });
      } else if (res['error'] != null) {
        setState(() {
          _connectionTestSuccess = false;
          _connectionTestResult = 'Error: ${res['error']}';
        });
      } else {
        setState(() {
          _connectionTestSuccess = true;
          _connectionTestResult = 'Server reached! (${stopwatch.elapsedMilliseconds} ms)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionTestSuccess = false;
          _connectionTestResult = 'Connection failed: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isTestingConnection = false);
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final isLocal = url.contains('127.0.0.1') ||
        url.contains('localhost') ||
        url.contains('10.0.2.2') ||
        url.startsWith('http://192.168.') ||
        url.startsWith('http://10.') ||
        url.startsWith('http://172.');

    if (!isLocal && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WAN/Internet backends must use secure HTTPS (https://).'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final success = await ApiConfig.setBaseUrl(url);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server URL updated and saved.'),
          backgroundColor: AppTheme.online,
        ),
      );
    }
  }

  Future<void> _resetUrl() async {
    await ApiConfig.resetBaseUrl();
    setState(() {
      _urlController.text = ApiConfig.baseUrl;
      _connectionTestResult = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset to compiled default URL.')),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out?',
      message: 'Are you sure you want to sign out from Laptop Guardian?',
      confirmText: 'Sign Out',
      confirmColor: AppTheme.offline,
      icon: Icons.logout_rounded,
    );

    if (!confirmed || !mounted) return;

    final authService = context.read<AuthService>();
    await authService.logout();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final fcm = context.watch<FcmService>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // User Profile Card
            if (_user != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _user!.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Server Backend Configuration Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Backend Server Connection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (ApiConfig.isHttps ? AppTheme.online : AppTheme.warning).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (ApiConfig.isHttps ? AppTheme.online : AppTheme.warning).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    ApiConfig.isHttps ? 'CLOUD HTTPS' : 'LOCAL DEV',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ApiConfig.isHttps ? AppTheme.online : AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Production requires a public HTTPS domain. For local development, HTTP localhost/LAN can be used.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _urlController,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Server Base URL',
                      prefixIcon: Icon(
                        Icons.cloud_queue_rounded,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_connectionTestResult != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_connectionTestSuccess == true
                                ? AppTheme.online
                                : AppTheme.offline)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_connectionTestSuccess == true
                                  ? AppTheme.online
                                  : AppTheme.offline)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _connectionTestSuccess == true
                                ? Icons.check_circle_rounded
                                : Icons.error_outline_rounded,
                            size: 16,
                            color: _connectionTestSuccess == true
                                ? AppTheme.online
                                : AppTheme.offline,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _connectionTestResult!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _connectionTestSuccess == true
                                    ? AppTheme.online
                                    : AppTheme.offline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isTestingConnection ? null : _testConnection,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          child: _isTestingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Test Ping'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveUrl,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          child: const Text('Save URL'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _resetUrl,
                    child: const Text(
                      'Reset to Default URL',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notifications Configuration Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        fcm.isReady ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                        color: fcm.isReady ? AppTheme.online : AppTheme.accent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Push Notifications (FCM)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fcm.isReady
                        ? 'FCM is connected and listening for remote push notifications across the internet.'
                        : 'Status: ${fcm.statusMessage}\n\nIn-app polling is active. To enable native push notifications across WAN, ensure google-services.json is present in android/app.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.offline,
                side: const BorderSide(color: AppTheme.offline),
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Sign Out'),
              onPressed: _handleLogout,
            ),
            const SizedBox(height: 24),

            // App Footer
            const Center(
              child: Text(
                'Laptop Guardian v1.0.0\nEnd-to-End Encrypted Cloud Telemetry',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
