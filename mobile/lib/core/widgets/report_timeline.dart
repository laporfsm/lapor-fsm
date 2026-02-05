import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/report_common/domain/entities/report_log.dart';

/// Shared Report Timeline widget for transparent log display
class ReportTimeline extends StatelessWidget {
  final List<ReportLog> logs;
  final Color? accentColor;

  const ReportTimeline({super.key, required this.logs, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < logs.length; i++)
          _buildLogItem(logs[i], i, logs.length, color),
      ],
    );
  }

  Widget _buildLogItem(ReportLog log, int index, int total, Color color) {
    final isFirst = index == 0;
    final isLast = index == total - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: isFirst ? Border.all(color: color, width: 3) : null,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const Gap(16),

          // Log content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log.action.label,
                        style: TextStyle(
                          fontWeight: isFirst
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDateTime(log.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    log.message,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  // Media evidence if available
                  if (log.mediaUrls != null && log.mediaUrls!.isNotEmpty) ...[
                    const Gap(8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.image,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const Gap(4),
                        Text(
                          'Bukti Penanganan (${log.mediaUrls!.length})',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Gap(6),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: log.mediaUrls!.length,
                        separatorBuilder: (_, __) => const Gap(8),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              // Open fullscreen viewer
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.black,
                                  insetPadding: EdgeInsets.zero,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: InteractiveViewer(
                                          child: Image.network(
                                            log.mediaUrls![index],
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 40,
                                        right: 16,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                log.mediaUrls![index],
                                height: 70,
                                width: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 70,
                                  width: 70,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    LucideIcons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}h lalu';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

extension ReportActionLabel on ReportAction {
  String get label {
    switch (this) {
      case ReportAction.created:
        return 'Laporan Dibuat';
      case ReportAction.verified:
        return 'Diverifikasi';
      case ReportAction.handling:
        return 'Penanganan';
      case ReportAction.completed:
        return 'Selesai';
      case ReportAction.rejected:
        return 'Ditolak';
      case ReportAction.approved:
        return 'Approved';
      case ReportAction.recalled:
        return 'Recalled';
      case ReportAction.overrideRejection:
        return 'Penolakan Dibatalkan';
      case ReportAction.approveRejection:
        return 'Penolakan Disetujui';
      case ReportAction.archived:
        return 'Diarsipkan';
      case ReportAction.paused:
        return 'Ditunda';
      case ReportAction.resumed:
        return 'Dilanjutkan';
      case ReportAction.grouped:
        return 'Digabungkan';
      case ReportAction.groupedChild:
        return 'Digabungkan ke Induk';
    }
  }
}
