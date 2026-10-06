import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../models/device.dart';
import '../models/command.dart';
import '../services/device_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/control_button.dart';
import '../widgets/confirm_dialog.dart';
import 'activity_screen.dart';
import 'location_screen.dart';

class DeviceScreen extends StatefulWidget {
  final String deviceId;
  final DeviceModel? initialDevice;

  const DeviceScreen({
    super.key,
    required this.deviceId,
    this.initialDevice,
  });

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  DeviceModel? _device;
  List<CommandModel> _commandHistory = [];
  bool _isLoading = true;
  String? _pendingCommand;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _device = widget.initialDevice;
    _fetchDetails();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _fetchDetails(isBackground: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDetails({bool isBackground = false}) async {
    if (!isBackground && _device == null) {
      setState(() => _isLoading = true);
    }

    try {
      final deviceService = context.read<DeviceService>();
      final data = await deviceService.deviceDetail(widget.deviceId);
      final history = await deviceService.commandHistory(widget.deviceId);

      if (mounted) {
        setState(() {
          if (data != null && data['device'] != null) {
            _device = DeviceModel.fromJson(data['device'] as Map<String, dynamic>);
          }
          _commandHistory = history;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !isBackground) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCommand(String command, {required String label, String? warning, bool isDestructive = false}) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '$label ${_device?.deviceName ?? "Device"}?',
      message: warning ?? 'Are you sure you want to execute $label on this device?',
      confirmText: label,
      confirmColor: isDestructive ? AppTheme.offline : AppTheme.accent,
      icon: isDestructive ? Icons.warning_amber_rounded : Icons.terminal_rounded,
    );

    if (!confirmed || !mounted) return;

    setState(() => _pendingCommand = command);

    final deviceService = context.read<DeviceService>();
    final res = await deviceService.sendCommand(widget.deviceId, command);

    if (!mounted) return;
    setState(() => _pendingCommand = null);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label command queued successfully.'),
          backgroundColor: AppTheme.online,
        ),
      );
      _fetchDetails(isBackground: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] as String? ?? 'Command failed to send.'),
          backgroundColor: AppTheme.offline,
        ),
      );
    }
  }

  Future<void> _handleRemoveDevice() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Remove ${_device?.deviceName ?? "Device"}?',
      message: 'This will remove the laptop from your account. You will need to re-pair it to monitor it again.',
      confirmText: 'Remove',
      confirmColor: AppTheme.offline,
      icon: Icons.delete_forever_rounded,
    );

    if (!confirmed || !mounted) return;

    final deviceService = context.read<DeviceService>();
    final success = await deviceService.removeDevice(widget.deviceId);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device removed successfully.'),
          backgroundColor: AppTheme.online,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove device.'),
          backgroundColor: AppTheme.offline,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _device;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(d?.deviceName ?? 'Device Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => _fetchDetails(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && d == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: () => _fetchDetails(),
              color: AppTheme.accent,
              backgroundColor: AppTheme.bgElevated,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // Device Hero Banner
                  _buildHeroBanner(d),
                  const SizedBox(height: 24),

                  // Remote Control Commands Grid
                  const Text(
                    'Remote Controls',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildControlsGrid(),
                  const SizedBox(height: 24),

                  // Quick navigation: Location & Activity Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildNavCard(
                          icon: Icons.map_rounded,
                          title: 'Location & Map',
                          subtitle: d?.city ?? 'View coordinates',
                          color: AppTheme.accent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LocationScreen(
                                  deviceId: widget.deviceId,
                                  deviceName: d?.deviceName ?? 'Laptop',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNavCard(
                          icon: Icons.history_rounded,
                          title: 'Activity Logs',
                          subtitle: 'Power & lock history',
                          color: AppTheme.accentAlt,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ActivityScreen(
                                  deviceId: widget.deviceId,
                                  deviceName: d?.deviceName ?? 'Laptop',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // System Information / Hardware Specs
                  const Text(
                    'Hardware & System Specs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSpecsCard(d),
                  const SizedBox(height: 24),

                  // Recent Commands History
                  if (_commandHistory.isNotEmpty) ...[
                    const Text(
                      'Recent Commands',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCommandHistoryCard(),
                    const SizedBox(height: 28),
                  ],

                  // Danger Zone: Unpair
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.offline,
                      side: const BorderSide(color: AppTheme.offline),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text('Unpair This Device'),
                    onPressed: _handleRemoveDevice,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroBanner(DeviceModel? d) {
    final isOnline = d?.isOnline ?? false;
    final lastSeenStr = d?.lastSeen != null
        ? DateFormat('h:mm a, MMM d, yyyy').format(d!.lastSeen!.toLocal())
        : 'Never';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? AppTheme.accent.withOpacity(0.35) : AppTheme.border,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOnline ? AppTheme.accent.withOpacity(0.15) : AppTheme.bgElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.laptop_chromebook,
                  color: isOnline ? AppTheme.accent : AppTheme.textSecondary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d?.deviceName ?? 'Laptop',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.deviceId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(isOnline: isOnline),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Heartbeat:',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                lastSeenStr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
          if (d?.batteryLevel != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Battery Level:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                Row(
                  children: [
                    Icon(
                      d!.batteryCharging
                          ? Icons.battery_charging_full_rounded
                          : Icons.battery_std_rounded,
                      size: 15,
                      color: d.batteryCharging ? AppTheme.online : AppTheme.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${d.batteryLevel}% ${d.batteryCharging ? "(Charging)" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        ControlButton(
          label: 'Lock Device',
          subtitle: 'Lock screen instantly',
          icon: Icons.lock_rounded,
          color: AppTheme.accent,
          isLoading: _pendingCommand == 'LOCK',
          onPressed: () => _handleCommand(
            'LOCK',
            label: 'Lock',
            warning: 'This will immediately lock the laptop workstation.',
          ),
        ),
        ControlButton(
          label: 'Play Alarm',
          subtitle: 'Sound alert on PC',
          icon: Icons.volume_up_rounded,
          color: AppTheme.warning,
          isLoading: _pendingCommand == 'ALARM',
          onPressed: () => _handleCommand(
            'ALARM',
            label: 'Sound Alarm',
            warning: 'This will play an audible alarm tone on the laptop speakers.',
          ),
        ),
        ControlButton(
          label: 'Webcam Photo',
          subtitle: 'Capture intruder photo',
          icon: Icons.camera_alt_rounded,
          color: const Color(0xFF38BDF8),
          isLoading: _pendingCommand == 'PHOTO',
          onPressed: () => _handleCommand(
            'PHOTO',
            label: 'Take Photo',
            warning: 'The laptop agent will secretly capture a webcam photo and upload it.',
          ),
        ),
        ControlButton(
          label: 'Screenshot',
          subtitle: 'Capture current desktop',
          icon: Icons.screenshot_rounded,
          color: const Color(0xFF818CF8),
          isLoading: _pendingCommand == 'SCREENSHOT',
          onPressed: () => _handleCommand(
            'SCREENSHOT',
            label: 'Capture Screenshot',
            warning: 'The laptop agent will capture a screenshot of the active desktop.',
          ),
        ),
        ControlButton(
          label: 'Sleep',
          subtitle: 'Put laptop to sleep',
          icon: Icons.bedtime_rounded,
          color: const Color(0xFFA78BFA),
          isLoading: _pendingCommand == 'SLEEP',
          onPressed: () => _handleCommand(
            'SLEEP',
            label: 'Sleep',
            warning: 'This puts the laptop into sleep mode.',
          ),
        ),
        ControlButton(
          label: 'Shutdown',
          subtitle: 'Full power down',
          icon: Icons.power_settings_new_rounded,
          isDestructive: true,
          isLoading: _pendingCommand == 'SHUTDOWN',
          onPressed: () => _handleCommand(
            'SHUTDOWN',
            label: 'Shutdown',
            warning: 'This will completely power off the laptop. You will not be able to send further commands until it is physically turned back on.',
            isDestructive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecsCard(DeviceModel? d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _specRow('Operating System', d?.os ?? 'Windows'),
          _specRow('Username', d?.username ?? 'Unknown'),
          _specRow('CPU', d?.cpu ?? 'Unknown'),
          _specRow('RAM', d?.ram ?? 'Unknown'),
          _specRow('GPU', d?.gpu ?? 'Integrated'),
          _specRow('Manufacturer', d?.manufacturer ?? 'PC'),
          _specRow('Model', d?.model ?? 'Desktop / Laptop'),
          _specRow('IP Address', d?.ipAddress ?? 'Unknown', isLast: true),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _commandHistory.take(5).length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cmd = _commandHistory[index];
          final timeStr = cmd.createdAt != null
              ? DateFormat('h:mm a').format(cmd.createdAt!)
              : '';

          Color statusColor;
          switch (cmd.status) {
            case 'EXECUTED':
              statusColor = AppTheme.online;
              break;
            case 'PENDING':
              statusColor = AppTheme.warning;
              break;
            case 'FAILED':
              statusColor = AppTheme.offline;
              break;
            default:
              statusColor = AppTheme.textSecondary;
          }

          return ListTile(
            dense: true,
            leading: Icon(
              Icons.terminal_rounded,
              color: statusColor,
              size: 20,
            ),
            title: Text(
              cmd.command,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cmd.errorMessage != null)
                  Text(
                    cmd.errorMessage!,
                    style: const TextStyle(fontSize: 11, color: AppTheme.offline),
                  )
                else
                  Text(
                    'Sent at $timeStr',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                if (cmd.result != null && cmd.result!.contains('/static/captures/')) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      final match = RegExp(r'(/static/captures/[^\s\)]+)').firstMatch(cmd.result!);
                      if (match != null) {
                        final imgUrl = '${ApiConfig.baseUrl}${match.group(1)}';
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: AppTheme.bgCard,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imgUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (_, child, prog) => prog == null
                                          ? child
                                          : const Padding(
                                              padding: EdgeInsets.all(40),
                                              child: CircularProgressIndicator(),
                                            ),
                                      errorBuilder: (_, __, ___) => const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text('Failed to load image', style: TextStyle(color: AppTheme.offline)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close', style: TextStyle(color: AppTheme.textPrimary)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_rounded, size: 14, color: AppTheme.accent),
                          SizedBox(width: 4),
                          Text('View Capture', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accent)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                cmd.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
