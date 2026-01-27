import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/core/widgets/fullscreen_map_modal.dart';
import 'package:mobile/core/widgets/media_gallery_widget.dart';
import 'package:mobile/core/widgets/report_timer_card.dart';
import 'package:mobile/core/widgets/report_timeline.dart';
import 'package:mobile/core/models/report_log.dart';
import 'package:mobile/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Category-specific header images
const _categoryImages = {
  'Maintenance':
      'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=800',
  'Emergency':
      'https://images.unsplash.com/photo-1587653915936-5623838a5c8c?w=800',
  'Kebersihan':
      'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=800',
  'Infrastruktur Kelas':
      'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=800',
  'Kelistrikan':
      'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=800',
  'Sipil & Bangunan':
      'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800',
  'Sanitasi':
      'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800',
};

const _defaultHeaderImage =
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800';

class ReportDetailBase extends StatelessWidget {
  final Report report;
  final UserRole viewerRole;
  final List<Widget>? actionButtons;

  const ReportDetailBase({
    super.key,
    required this.report,
    required this.viewerRole,
    this.actionButtons,
  });

  /// Get category-specific header image
  String get _headerImage {
    // Priority: custom imageUrl > category image > default
    if (report.imageUrl != null) return report.imageUrl!;
    return _categoryImages[report.category] ?? _defaultHeaderImage;
  }

  void _launchPhone(String? phoneNumber) async {
    if (phoneNumber == null) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  String _formatDurationReadable(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours jam $minutes menit';
    }
    return '$minutes menit';
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Header with Image & Title
          _buildSliverAppBar(context),

          // 2. Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timer (Pelapor Style) - Only if not finished
                  if (report.status != ReportStatus.selesai &&
                      report.status != ReportStatus.ditolak &&
                      report.status != ReportStatus.approved) ...[
                    ReportTimerCard(
                      createdAt: report.createdAt,
                      isEmergency: report.isEmergency,
                    ),
                    const Gap(16),
                  ],

                  // Status Card
                  _buildStatusCard(),
                  const Gap(16),

                  // Media Evidence Gallery
                  if (report.mediaUrls != null &&
                      report.mediaUrls!.isNotEmpty) ...[
                    MediaGalleryWidget(mediaUrls: report.mediaUrls!),
                    const Gap(16),
                  ],
                  const Gap(16),

                  // Reporter Info (Visible to Teknisi, Supervisor, & PJ Gedung)
                  if (viewerRole == UserRole.teknisi ||
                      viewerRole == UserRole.supervisor ||
                      viewerRole == UserRole.pjGedung) ...[
                    _buildInfoCard(
                      title: 'Informasi Pelapor',
                      icon: LucideIcons.user,
                      accentColor: AppTheme.primaryColor,
                      children: [
                        _buildInfoRow(
                          LucideIcons.user,
                          'Nama',
                          report.reporterName,
                        ),
                        if (report.reporterEmail != null)
                          _buildInfoRow(
                            LucideIcons.mail,
                            'Email',
                            report.reporterEmail!,
                          ),
                        if (report.reporterPhone != null)
                          _buildInfoRowWithAction(
                            LucideIcons.phone,
                            'Telepon',
                            report.reporterPhone!,
                            onTap: () => _launchPhone(report.reporterPhone),
                          ),
                      ],
                    ),
                    const Gap(16),
                  ],

                  // Handled By (Visible to Everyone if assigned)
                  if (report.handledBy != null &&
                      report.handledBy!.isNotEmpty) ...[
                    _buildInfoCard(
                      title: 'Ditangani Oleh',
                      icon: LucideIcons.wrench,
                      accentColor: AppTheme.secondaryColor,
                      children: report.handledBy!
                          .map(
                            (tech) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Text(
                                      tech,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const Gap(16),
                  ],

                  // Supervisor (Visible if supervised)
                  if (report.supervisorName != null) ...[
                    _buildInfoCard(
                      title: 'Diverifikasi Oleh',
                      icon: LucideIcons.checkCircle2,
                      accentColor: AppTheme.supervisorColor,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.supervisorColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                report.supervisorName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Gap(16),
                  ],

                  // Time Breakdown (for completed/approved reports)
                  if (report.handlingStartedAt != null &&
                      report.completedAt != null) ...[
                    _buildInfoCard(
                      title: 'Waktu Penanganan',
                      icon: LucideIcons.timer,
                      accentColor: Colors.green,
                      children: [
                        // Total handling time
                        () {
                          final totalTime = report.completedAt!.difference(
                            report.handlingStartedAt!,
                          );
                          final holdDuration = Duration(
                            seconds: report.totalPausedDurationSeconds,
                          );
                          final actualTime = totalTime - holdDuration;

                          return Column(
                            children: [
                              // Actual Work Time
                              _buildInfoRow(
                                LucideIcons.hammer,
                                'Waktu Pengerjaan',
                                _formatDurationReadable(actualTime),
                              ),
                              // Hold Time (if any)
                              if (holdDuration.inSeconds > 0)
                                _buildInfoRow(
                                  LucideIcons.pauseCircle,
                                  'Waktu Hold',
                                  _formatDurationReadable(holdDuration),
                                ),
                              const Gap(8),
                              const Divider(),
                              const Gap(8),
                              // Started At
                              _buildInfoRow(
                                LucideIcons.play,
                                'Mulai Dikerjakan',
                                _formatDateTime(report.handlingStartedAt!),
                              ),
                              // Completed At
                              _buildInfoRow(
                                LucideIcons.checkCircle2,
                                'Selesai Dikerjakan',
                                _formatDateTime(report.completedAt!),
                              ),
                            ],
                          );
                        }(),
                      ],
                    ),
                    const Gap(16),
                  ],

                  // Location Card with Map
                  _buildInfoCard(
                    title: 'Lokasi',
                    icon: LucideIcons.mapPin,
                    accentColor: Colors.red,
                    children: [
                      _buildInfoRow(
                        LucideIcons.building,
                        'Gedung',
                        report.building,
                      ),
                      if (report.latitude != null &&
                          report.longitude != null) ...[
                        const Gap(12),
                        _buildMapPreview(context),
                      ],
                    ],
                  ),
                  const Gap(16),

                  // Description
                  _buildInfoCard(
                    title: 'Deskripsi',
                    icon: LucideIcons.fileText,
                    accentColor: Colors.grey,
                    children: [
                      Text(
                        report.description,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Timeline
                  _buildInfoCard(
                    title: 'Riwayat Aktivitas',
                    icon: LucideIcons.clock,
                    accentColor: AppTheme.primaryColor,
                    children: [
                      ReportTimeline(
                        logs: [
                          ReportLog(
                            id: 'created_${report.id}',
                            fromStatus: ReportStatus.pending, // Initial
                            toStatus: ReportStatus.pending,
                            action: ReportAction
                                .created, // Map to "Laporan Dibuat" in UI
                            actorId: report.reporterId,
                            actorName: report.reporterName,
                            actorRole: 'Pelapor',
                            timestamp: report.createdAt,
                          ),
                          ...report.logs,
                        ],
                      ),
                    ],
                  ),

                  const Gap(100), // Bottom padding for FAB/Buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: actionButtons != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: actionButtons!
                    .map(
                      (btn) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: btn,
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
          : null,
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.arrowLeft,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Header Image (category-based or custom)
            Image.network(
              _headerImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Icon(
                  LucideIcons.image,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),

            // Emergency Badge
            if (report.isEmergency)
              Positioned(
                top: 80,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.emergencyColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        color: Colors.white,
                        size: 14,
                      ),
                      Gap(4),
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
              ),

            // Title and Category
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      report.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    report.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = AppTheme.getStatusColor(report.status.name);
    final statusIcon = AppTheme.getStatusIcon(report.status.name);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Laporan',
                style: TextStyle(
                  color: statusColor.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                report.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const Gap(8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const Gap(12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithAction(
    IconData icon,
    String label,
    String value, {
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const Gap(12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(report.latitude!, report.longitude!),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.laporfsm.mobile',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(report.latitude!, report.longitude!),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => FullscreenMapModal(
                      latitude: report.latitude!,
                      longitude: report.longitude!,
                      locationName: report.building,
                    ),
                  );
                },
                icon: const Icon(LucideIcons.maximize2, size: 14),
                label: const Text('Lihat Peta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
