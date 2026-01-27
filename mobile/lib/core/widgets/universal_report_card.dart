import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/theme.dart';

/// Universal Report Card widget for consistent display across the app.
/// Use this for all report list displays (Teknisi, Supervisor, Pelapor).
class UniversalReportCard extends StatelessWidget {
  final String id;
  final String title;
  final String location;
  final String category;
  final ReportStatus? status;
  final bool isEmergency;
  final Duration? elapsedTime;
  final Duration? handlingTime; // Waktu pengerjaan (for completed reports)
  final Duration? holdTime; // Waktu hold (optional)
  final String? handledBy;
  final VoidCallback? onTap;
  final Widget? actionButton;
  final bool showStatus;
  final bool showTimer;
  final bool compact;

  const UniversalReportCard({
    super.key,
    required this.id,
    required this.title,
    required this.location,
    required this.category,
    this.status,
    this.isEmergency = false,
    this.elapsedTime,
    this.handlingTime,
    this.holdTime,
    this.handledBy,
    this.onTap,
    this.actionButton,
    this.showStatus = false,
    this.showTimer = true,
    this.compact = false,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (elapsedTime == null) return Colors.grey;
    if (elapsedTime!.inMinutes >= 30) return Colors.red;
    if (elapsedTime!.inMinutes >= 15) return Colors.orange;
    return AppTheme.secondaryColor;
  }

  String _formatCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isEmergency
              ? Border.all(color: AppTheme.emergencyColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isEmergency
                  ? AppTheme.emergencyColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Banner
            if (isEmergency)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: AppTheme.emergencyColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      color: Colors.white,
                      size: 14,
                    ),
                    Gap(6),
                    Text(
                      'DARURAT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: EdgeInsets.all(compact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Status Badge + Timer
                  Row(
                    children: [
                      // Status Badge
                      if (showStatus && status != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status!.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status!.label.toUpperCase(),
                            style: TextStyle(
                              color: status!.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ] else
                        const Spacer(),

                      // Timer OR Handling/Hold Times
                      if (handlingTime != null) ...[
                        // Handling Time (for completed reports)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.timer,
                                size: 12,
                                color: Colors.green,
                              ),
                              const Gap(4),
                              Text(
                                _formatCompact(handlingTime!),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Hold Time (optional)
                        if (holdTime != null && holdTime!.inSeconds > 0) ...[
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.pauseCircle,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                                const Gap(4),
                                Text(
                                  _formatCompact(holdTime!),
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else if (showTimer && elapsedTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _timerColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.timer,
                                size: 12,
                                color: _timerColor,
                              ),
                              const Gap(4),
                              Text(
                                _formatDuration(elapsedTime!),
                                style: TextStyle(
                                  color: _timerColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  if (showStatus || (showTimer && elapsedTime != null))
                    const Gap(10),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 14 : 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Gap(6),

                  // Location & Category
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const Gap(4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(12),
                      Icon(
                        LucideIcons.tag,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const Gap(4),
                      Text(
                        category,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Handled By
                  if (handledBy != null && !compact) ...[
                    const Gap(8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.wrench,
                          size: 13,
                          color: AppTheme.secondaryColor,
                        ),
                        const Gap(4),
                        Expanded(
                          child: Text(
                            'Ditangani: $handledBy',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Action Button
                  if (actionButton != null) ...[
                    const Gap(12),
                    SizedBox(width: double.infinity, child: actionButton),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
