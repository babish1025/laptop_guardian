import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final bool isOnline;
  final String? label;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.isOnline,
    this.label,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppTheme.online : AppTheme.offline;
    final text = label ?? (isOnline ? 'ONLINE' : 'OFFLINE');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
