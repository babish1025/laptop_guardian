import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/device.dart';
import 'status_badge.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onTap;
  final VoidCallback? onLock;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = device.isOnline;
    final lastSeenStr = device.lastSeen != null
        ? DateFormat('h:mm a, MMM d').format(device.lastSeen!.toLocal())
        : 'Never';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? AppTheme.accent.withOpacity(0.3) : AppTheme.border,
          width: isOnline ? 1.5 : 1.0,
        ),
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Laptop Icon + Name + Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? AppTheme.accent.withOpacity(0.15)
                            : AppTheme.bgElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOnline
                              ? AppTheme.accent.withOpacity(0.3)
                              : AppTheme.border,
                        ),
                      ),
                      child: Icon(
                        Icons.laptop_chromebook,
                        color: isOnline ? AppTheme.accent : AppTheme.textSecondary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.deviceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            device.os ?? 'Windows PC',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
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
                const SizedBox(height: 14),

                // Specs & Info chips row
                Row(
                  children: [
                    // Battery
                    if (device.batteryLevel != null) ...[
                      Row(
                        children: [
                          Icon(
                            device.batteryCharging
                                ? Icons.battery_charging_full_rounded
                                : (device.batteryLevel! > 20
                                    ? Icons.battery_std_rounded
                                    : Icons.battery_alert_rounded),
                            size: 16,
                            color: device.batteryCharging
                                ? AppTheme.online
                                : (device.batteryLevel! > 20
                                    ? AppTheme.textSecondary
                                    : AppTheme.offline),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${device.batteryLevel}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                    ],

                    // IP Address / Network
                    if (device.ipAddress != null &&
                        device.ipAddress!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.wifi_rounded,
                            size: 15,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            device.ipAddress!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                    ],

                    const Spacer(),

                    // Last seen text
                    Text(
                      isOnline ? 'Active now' : 'Seen $lastSeenStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOnline ? AppTheme.online : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Location line
                if (device.locationLabel != 'Location unavailable') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          device.locationLabel,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
