import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../models/device.dart';
import '../models/user.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../widgets/device_card.dart';
import '../widgets/confirm_dialog.dart';
import 'device_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _user;
  List<DeviceModel> _devices = [];
  bool _isLoading = true;
  String? _error;
  int _unreadNotifications = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(ApiConfig.dashboardRefreshInterval, (_) {
      if (mounted) _fetchData(isBackground: true);
    });
  }

  Future<void> _loadUser() async {
    final storage = context.read<StorageService>();
    final user = await storage.getUser();
    if (mounted) {
      setState(() => _user = user);
    }
  }

  Future<void> _fetchData({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final deviceService = context.read<DeviceService>();
      final devices = await deviceService.listDevices();
      final unread = await deviceService.unreadCount();

      if (mounted) {
        setState(() {
          _devices = devices;
          _unreadNotifications = unread;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isBackground) {
        setState(() {
          _error = 'Failed to load devices: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _quickLock(DeviceModel device) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Lock ${device.deviceName}?',
      message: 'This will immediately lock the laptop workstation.',
      confirmText: 'Lock Now',
      confirmColor: AppTheme.accent,
      icon: Icons.lock_outline_rounded,
    );

    if (!confirmed || !mounted) return;

    final deviceService = context.read<DeviceService>();
    final res = await deviceService.sendCommand(device.deviceId, 'LOCK');

    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lock command dispatched to ${device.deviceName}'),
          backgroundColor: AppTheme.online,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] as String? ?? 'Failed to send command'),
          backgroundColor: AppTheme.offline,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _devices.where((d) => d.isOnline).length;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laptop Guardian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            if (_user != null)
              Text(
                'Signed in as ${_user!.name}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          // Refresh action
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => _fetchData(),
            tooltip: 'Refresh',
          ),
          // Settings action with unread alert badge
          IconButton(
            icon: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text('$_unreadNotifications'),
              child: const Icon(Icons.settings_outlined, size: 22),
            ),
            onPressed: () async {
              await Navigator.of(context).pushNamed('/settings');
              _fetchData();
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchData(),
        color: AppTheme.accent,
        backgroundColor: AppTheme.bgElevated,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Top Summary Stats Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  label: 'Online Laptops',
                                  value: '$onlineCount / ${_devices.length}',
                                  icon: Icons.wifi_rounded,
                                  color: onlineCount > 0
                                      ? AppTheme.online
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildStatCard(
                                  label: 'System Status',
                                  value: onlineCount > 0 ? 'Protected' : 'Standby',
                                  icon: Icons.shield_outlined,
                                  color: onlineCount > 0
                                      ? AppTheme.accent
                                      : AppTheme.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'My Devices',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/pairing');
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 16,
                                  color: AppTheme.accent,
                                ),
                                label: const Text(
                                  'Pair Device',
                                  style: TextStyle(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error state if any
                  if (_error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.offline.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.offline.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.offline),
                          ),
                        ),
                      ),
                    ),

                  // Empty state
                  if (_devices.isEmpty && _error == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgElevated,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: const Icon(
                                  Icons.laptop_mac_rounded,
                                  size: 56,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No Laptops Paired Yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Generate a pairing code and enter it into the Laptop Guardian agent on your laptop.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(200, 48),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/pairing');
                                },
                                icon: const Icon(Icons.qr_code_rounded, size: 20),
                                label: const Text('Generate Pairing Code'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // Device List
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final device = _devices[index];
                            return DeviceCard(
                              device: device,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DeviceScreen(
                                      deviceId: device.deviceId,
                                      initialDevice: device,
                                    ),
                                  ),
                                );
                                _fetchData();
                              },
                              onLock: () => _quickLock(device),
                            );
                          },
                          childCount: _devices.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
      floatingActionButton: _devices.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              onPressed: () {
                Navigator.of(context).pushNamed('/pairing');
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Pair Device',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
