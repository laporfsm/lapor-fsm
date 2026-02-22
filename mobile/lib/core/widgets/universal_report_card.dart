import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/theme.dart';

/// Universal Report Card widget for consistent display across the app.
/// Use this for all report list displays (Teknisi, Supervisor, Pelapor).
class UniversalReportCard extends StatelessWidget {
  final String id;
  final String title;
  final String location;
  final String? locationDetail; // New field
  final String category;
  final ReportStatus? status;
  final bool isEmergency;
  final Duration? elapsedTime;
  final Duration? handlingTime; // Waktu pengerjaan (for completed reports)
  final Duration? holdTime; // Waktu hold (optional)
  final String? handledBy;
  final String? reporterName; // New field
  final VoidCallback? onTap;
  final Widget? actionButton;
  final bool showStatus;
  final bool showTimer;
  final bool compact;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const UniversalReportCard({
    super.key,
    required this.id,
    required this.title,
    required this.location,
    this.locationDetail,
    required this.category,
    this.status,
    this.isEmergency = false,
    this.elapsedTime,
    this.handlingTime,
    this.holdTime,
    this.handledBy,
    this.reporterName,
    this.onTap,
    this.actionButton,
    this.showStatus = false,
    this.showTimer = true,
    this.compact = false,
    this.selectionMode = false,
    this.isSelected = false,
    this.onLongPress,
  });

  // ... (keeping methods same)

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
    if (elapsedTime!.inHours >= 24) return Colors.orange;
    return AppTheme.primaryColor;
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return LucideIcons.clock;
      case ReportStatus.terverifikasi:
      case ReportStatus.verifikasi:
        return LucideIcons.checkCircle;
      case ReportStatus.diproses:
        return LucideIcons.userCheck;
      case ReportStatus.penanganan:
        return LucideIcons.wrench;
      case ReportStatus.onHold:
        return LucideIcons.pauseCircle;
      case ReportStatus.selesai:
        return LucideIcons.checkSquare;
      case ReportStatus.approved:
        return LucideIcons.badgeCheck;
      case ReportStatus.ditolak:
        return LucideIcons.xCircle;
      case ReportStatus.recalled:
        return LucideIcons.rotateCcw;
      case ReportStatus.archived:
        return LucideIcons.archive;
    }
  }

  String _formatCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) return '${hours}j ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      onLongPress: onLongPress,
      scaleFactor: 0.98,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : (isEmergency
                        ? Border.all(color: AppTheme.emergencyColor, width: 2)
                        : Border.all(color: Colors.grey.shade100)),
              boxShadow: [
                BoxShadow(
                  color: isEmergency
                      ? AppTheme.emergencyColor.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEmergency)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: const BoxDecoration(
                      color: AppTheme.emergencyColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
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
                      Row(
                        children: [
                          if (showStatus && status != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status!.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: status!.color.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(status!),
                                    size: 10,
                                    color: status!.color,
                                  ),
                                  const Gap(4),
                                  Text(
                                    status!.label.toUpperCase(),
                                    style: TextStyle(
                                      color: status!.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                          ] else
                            const Spacer(),

                          if (handlingTime != null) ...[
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

                      const Gap(12),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: compact ? 14 : 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(12),

                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const Gap(4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        location,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (locationDetail != null &&
                                          locationDetail!.isNotEmpty)
                                        Text(
                                          locationDetail!,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.tag,
                                  size: 12,
                                  color: Colors.blue.shade700,
                                ),
                                const Gap(4),
                                Text(
                                  category,
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Info Pelapor & Handler
                      if (!compact) ...[
                        if (reporterName != null || handledBy != null)
                          const Divider(height: 24),

                        if (reporterName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.user,
                                  size: 13,
                                  color: Colors.blueGrey,
                                ),
                                const Gap(4),
                                Expanded(
                                  child: Text(
                                    'Pelapor: $reporterName',
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (handledBy != null)
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
                                ),
                              ),
                            ],
                          ),
                      ],

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
          if (selectionMode)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.check,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
