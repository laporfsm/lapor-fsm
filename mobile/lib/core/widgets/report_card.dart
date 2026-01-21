import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import '../enums/report_status.dart';
import '../enums/user_role.dart';
import '../models/report.dart';

/// Shared Report Card widget with role-based rendering
class ReportCard extends StatefulWidget {
  final Report report;
  final UserRole viewerRole;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool showTimer;

  const ReportCard({
    super.key,
    required this.report,
    required this.viewerRole,
    required this.onTap,
    this.onAction,
    this.actionLabel,
    this.showTimer = true,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.showTimer && widget.report.isActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final role = widget.viewerRole;
    final statusColor = AppTheme.getStatusColor(report.status.name);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          border: report.isEmergency
              ? Border.all(color: AppTheme.emergencyColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: report.isEmergency
                  ? AppTheme.emergencyColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Banner
            if (report.isEmergency) _buildEmergencyBanner(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Status + Category + Timer
                  _buildTopRow(statusColor),
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
                  _buildLocationRow(),

                  // Role-specific info (Reporter info only for Teknisi/Supervisor in early stages)
                  if (role.canContactReporter && _showReporterInfo())
                    _buildReporterInfo(),

                  // Handled By info (Visible to ALL roles if someone is handling it)
                  if (report.handledBy != null && report.handledBy!.isNotEmpty)
                    _buildHandledByInfo(),

                  // Supervisor Approved By (Visible for Approved reports)
                  if (report.status == ReportStatus.approved &&
                      report.supervisorName != null)
                    _buildApprovedByInfo(),

                  // Action Button (Role specific)
                  if (widget.onAction != null && widget.actionLabel != null)
                    _buildActionButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.emergencyColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardBorderRadius - 2),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertTriangle, color: Colors.white, size: 16),
          Gap(6),
          Text(
            'DARURAT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRow(Color statusColor) {
    final report = widget.report;

    return Row(
      children: [
        // Status Badge (Standardized for all)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppTheme.getStatusIcon(report.status.name),
                size: 12,
                color: statusColor,
              ),
              const Gap(4),
              Text(
                report.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const Gap(8),

        // Category Badge (Standardized for all)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            report.category,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
        ),

        const Spacer(),

        // Timer (if active & enabled) OR Relative Time
        if (widget.showTimer && report.isActive)
          _buildTimer()
        else
          Text(
            _formatRelativeTime(report.createdAt),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
      ],
    );
  }

  Widget _buildTimer() {
    final elapsed = widget.report.elapsed;
    final isOverdue = elapsed.inMinutes >= 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppTheme.emergencyColor.withOpacity(0.1)
            : AppTheme.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.clock,
            size: 12,
            color: isOverdue
                ? AppTheme.emergencyColor
                : AppTheme.secondaryColor,
          ),
          const Gap(4),
          Text(
            _formatDuration(elapsed),
            style: TextStyle(
              color: isOverdue
                  ? AppTheme.emergencyColor
                  : AppTheme.secondaryColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Icon(LucideIcons.mapPin, size: 14, color: Colors.grey.shade500),
        const Gap(6),
        Expanded(
          child: Text(
            widget.report.building,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  bool _showReporterInfo() {
    final status = widget.report.status;
    return status == ReportStatus.pending || status == ReportStatus.verifikasi;
  }

  Widget _buildReporterInfo() {
    final report = widget.report;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(LucideIcons.user, size: 14, color: Colors.grey.shade500),
          const Gap(6),
          Text(
            report.reporterName,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          if (report.reporterPhone != null) ...[
            const Gap(12),
            Icon(LucideIcons.phone, size: 14, color: Colors.grey.shade500),
            const Gap(6),
            Text(
              report.reporterPhone!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHandledByInfo() {
    final report = widget.report;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(LucideIcons.wrench, size: 14, color: AppTheme.secondaryColor),
          const Gap(6),
          Expanded(
            child: Text(
              'Ditangani: ${report.handledBy!.join(", ")}',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedByInfo() {
    final report = widget.report;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle2, size: 14, color: Colors.green),
          const Gap(6),
          Expanded(
            child: Text(
              'Disetujui: ${report.supervisorName}',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final report = widget.report;
    final isPending = report.status == ReportStatus.pending;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.onAction,
          icon: Icon(
            isPending ? LucideIcons.eye : LucideIcons.clipboardCheck,
            size: 18,
          ),
          label: Text(widget.actionLabel!),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPending
                ? (report.isEmergency
                      ? AppTheme.emergencyColor
                      : AppTheme.primaryColor)
                : Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}j ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}d';
    } else {
      return '${seconds}d';
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }
}
