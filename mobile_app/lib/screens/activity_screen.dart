import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/activity.dart';
import '../services/device_service.dart';
import '../widgets/activity_tile.dart';

class ActivityScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const ActivityScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<ActivityModel> _activities = [];
  bool _isLoading = true;
  String _selectedPeriod = '7d';

  final _periods = const [
    {'label': '24 Hours', 'value': '24h'},
    {'label': '7 Days', 'value': '7d'},
    {'label': '30 Days', 'value': '30d'},
    {'label': 'All Time', 'value': 'all'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoading = true);
    try {
      final deviceService = context.read<DeviceService>();
      final list = await deviceService.activityHistory(
        widget.deviceId,
        period: _selectedPeriod,
      );
      if (mounted) {
        setState(() {
          _activities = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showActivityDetail(ActivityModel act) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final timeStr = act.createdAt != null
            ? DateFormat('EEEE, MMMM d, yyyy  h:mm:ss a').format(act.createdAt!)
            : 'Unknown';

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(act.eventIcon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act.eventLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          timeStr,
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
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              if (act.eventDetails != null && act.eventDetails!.isNotEmpty) ...[
                const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  act.eventDetails!,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
              ],
              if (act.locationLabel != null || act.latitude != null) ...[
                const Text(
                  'Location at Event',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  act.locationLabel ??
                      '${act.latitude?.toStringAsFixed(4)}, ${act.longitude?.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.accent),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Timeline'),
            Text(
              widget.deviceName,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter pills row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.bgDark,
            child: Row(
              children: _periods.map((p) {
                final isSelected = _selectedPeriod == p['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(p['label']!),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedPeriod = p['value']!);
                        _fetchActivities();
                      }
                    },
                    selectedColor: AppTheme.accent.withOpacity(0.2),
                    backgroundColor: AppTheme.bgElevated,
                    checkmarkColor: AppTheme.accent,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.accent : AppTheme.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Timeline / List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchActivities,
                    color: AppTheme.accent,
                    backgroundColor: AppTheme.bgElevated,
                    child: _activities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 48,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Activities Recorded',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No events in the selected time range ($_selectedPeriod)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _activities.length,
                            itemBuilder: (context, index) {
                              final act = _activities[index];
                              return ActivityTile(
                                activity: act,
                                onTap: () => _showActivityDetail(act),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
