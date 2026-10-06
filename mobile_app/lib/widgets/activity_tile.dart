import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/activity.dart';

class ActivityTile extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onTap;

  const ActivityTile({
    super.key,
    required this.activity,
    this.onTap,
  });

  Color _getEventColor(String type) {
    switch (type) {
      case 'STARTUP':
      case 'UNLOCK':
      case 'WAKE':
        return AppTheme.online;
      case 'SHUTDOWN':
      case 'LOCK':
        return const Color(0xFF38BDF8);
      case 'SLEEP':
        return const Color(0xFFA78BFA);
      case 'UNEXPECTED_OFFLINE':
        return AppTheme.offline;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getEventColor(activity.eventType);
    final timeStr = activity.createdAt != null
        ? DateFormat('MMM d, h:mm a').format(activity.createdAt!)
        : 'Unknown time';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    activity.eventIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.eventLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (activity.eventDetails != null &&
                          activity.eventDetails!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          activity.eventDetails!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (activity.locationLabel != null &&
                          activity.locationLabel!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activity.locationLabel!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.accent,
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
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
