import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/report.dart';
import '../../domain/enums/report_status.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../theme.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;
  final String? actionLabel; // Optional action button label
  final VoidCallback? onAction; // Optional action callback
  final UserRole? viewerRole; // Optional for styling context

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    this.actionLabel,
    this.onAction,
    this.viewerRole,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: report.isEmergency
              ? Border.all(color: Colors.red, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID/Date & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (report.isEmergency)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.alertTriangle,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const Gap(4),
                                const Text(
                                  'DARURAT',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          '#${report.id} • ${DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: report.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      report.status.label.toUpperCase(),
                      style: TextStyle(
                        color: report.status.color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(10),

              // Title
              Text(
                report.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Gap(8),

              // Location
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const Gap(6),
                  Expanded(
                    child: Text(
                      report.building, // Or full location if available
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(6),

              // Reporter or Category info (Optional depending on role, showing category for now)
              Row(
                children: [
                  Icon(LucideIcons.tag, size: 14, color: Colors.grey.shade500),
                  const Gap(6),
                  Text(
                    report.category,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),

              // Action Button
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      onAction ??
                      onTap, // Use onAction if provided, else onTap (or just onTap which goes to details)
                  // If actionLabel is specific (e.g. "Verifikasi"), onAction might be different from onTap.
                  // If onAction is null, we can default to 'Lihat Detail' with onTap.
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: actionLabel != null
                        ? AppTheme.primaryColor
                        : null,
                    foregroundColor: actionLabel != null
                        ? Colors.white
                        : Colors.black87,
                  ),
                  child: Text(
                    actionLabel ?? 'Lihat Detail',
                    style: TextStyle(
                      color: actionLabel != null
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: actionLabel != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
