import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/core/services/websocket_service.dart';
import 'package:mobile/core/services/sse_service.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/domain/enums/user_role.dart';
import 'package:mobile/core/widgets/fullscreen_map_modal.dart';
import 'package:mobile/core/widgets/media_gallery_widget.dart';
import 'package:mobile/core/widgets/report_timer_card.dart';
import 'package:mobile/core/widgets/report_timeline.dart';
import 'package:mobile/features/report_common/domain/entities/report_log.dart';
import 'package:mobile/core/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportDetailBase extends StatefulWidget {
  final Report report;
  final UserRole viewerRole;
  final List<Widget>? actionButtons;
  final Color? appBarColor;
  final VoidCallback? onReportChanged;

  const ReportDetailBase({
    super.key,
    required this.report,
    required this.viewerRole,
    this.actionButtons,
    this.appBarColor,
    this.onReportChanged,
  });

  @override
  State<ReportDetailBase> createState() => _ReportDetailBaseState();
}

class _ReportDetailBaseState extends State<ReportDetailBase> {
  LatLng? _liveLatLng;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _sseSubscription;
  Timer? _locationBroadcastTimer;
  List<ReportLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _logs = widget.report.logs;
    _setupTracking();
    _setupSSE();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _sseSubscription?.cancel();
    _locationBroadcastTimer?.cancel();
    sseService.disconnect();
    if (widget.report.isEmergency) {
      webSocketService.disconnect();
    }
    super.dispose();
  }

  void _setupSSE() {
    // Connect to SSE for real-time logs
    sseService.connect(widget.report.id);

    // Listen to SSE stream
    _sseSubscription = sseService.logsStream.listen((logs) {
      if (mounted && logs.isNotEmpty) {
        // Check if the latest log indicates a status change
        final latestLog = logs.first; // logs are ordered desc by timestamp
        final currentStatus = widget.report.status.name;
        final newStatus = latestLog.toStatus.name;

        setState(() {
          _logs = logs;
        });

        // If status changed, trigger full report re-fetch
        if (newStatus != currentStatus && widget.onReportChanged != null) {
          debugPrint(
            '[SSE] Status change detected: $currentStatus -> $newStatus, triggering refresh',
          );
          widget.onReportChanged!();
        }
      }
    });
  }

  void _setupTracking() {
    // Don't track if finished
    if (widget.report.status == ReportStatus.selesai ||
        widget.report.status == ReportStatus.ditolak ||
        widget.report.status == ReportStatus.approved) {
      return;
    }

    // 1. Connect WS
    webSocketService.connect(widget.report.id);

    // 2. Listen for updates
    _wsSubscription = webSocketService.stream?.listen((event) {
      try {
        final data = jsonDecode(event);
        if (data['action'] == 'location_update') {
          setState(() {
            _liveLatLng = LatLng(
              data['latitude'] as double,
              data['longitude'] as double,
            );
          });
          debugPrint('[TRACKING] Received update: $_liveLatLng');
        }
      } catch (e) {
        debugPrint('[TRACKING] Error parsing WS message: $e');
      }
    });

    // 3. If I am the reporter, broadcast my location
    if (widget.viewerRole == UserRole.pelapor) {
      _startSelfBroadcasting();
    }

    // 4. If I am the assigned technician and status is penanganan, broadcast my location
    if (widget.viewerRole == UserRole.teknisi &&
        widget.report.status == ReportStatus.penanganan) {
      _startTechnicianBroadcasting();
    }
  }

  Future<void> _startSelfBroadcasting() async {
    _locationBroadcastTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      try {
        final position = await locationService.getCurrentPosition();

        if (position != null) {
          final user = await authService.getCurrentUser();
          final name = user?['name'] ?? 'Pelapor';

          webSocketService.sendLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            role: 'pelapor',
            senderName: name,
          );

          // Update local UI immediately too
          if (mounted) {
            setState(() {
              _liveLatLng = LatLng(position.latitude, position.longitude);
            });
          }
        }
      } catch (e) {
        debugPrint('[TRACKING] Failed to broadcast location: $e');
      }
    });
  }

  Future<void> _startTechnicianBroadcasting() async {
    _locationBroadcastTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      try {
        final position = await locationService.getCurrentPosition();

        if (position != null) {
          final user = await authService.getCurrentUser();
          final name = user?['name'] ?? 'Teknisi';
          final userId = user?['id']?.toString();

          // Only broadcast if this technician is assigned to the report
          if (userId != null && widget.report.assignedTo == userId) {
            webSocketService.sendLocation(
              latitude: position.latitude,
              longitude: position.longitude,
              role: 'teknisi',
              senderName: name,
            );

            debugPrint(
              '[TRACKING] Technician location broadcast: ${position.latitude}, ${position.longitude}',
            );

            // Update local UI immediately too
            if (mounted) {
              setState(() {
                _liveLatLng = LatLng(position.latitude, position.longitude);
              });
            }
          }
        }
      } catch (e) {
        debugPrint('[TRACKING] Failed to broadcast technician location: $e');
      }
    });
  }

  /// Get category-specific header image

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
                  if (widget.report.status != ReportStatus.selesai &&
                      widget.report.status != ReportStatus.ditolak &&
                      widget.report.status != ReportStatus.approved) ...[
                    ReportTimerCard(
                      createdAt: widget.report.createdAt,
                      isEmergency: widget.report.isEmergency,
                    ),
                    const Gap(16),
                  ],

                  // Status Card
                  _buildStatusCard(),
                  const Gap(16),

                  // Media Evidence Gallery (Always show logic)
                  MediaGalleryWidget(
                    mediaUrls:
                        (widget.report.mediaUrls != null &&
                            widget.report.mediaUrls!.isNotEmpty)
                        ? widget.report.mediaUrls!
                        : const [
                            'https://images.unsplash.com/photo-1581094288338-2314dddb7ece?auto=format&fit=crop&q=80',
                          ],
                  ),
                  const Gap(16),

                  // Reporter Info (Visible to Everyone)
                  _buildInfoCard(
                    title: 'Informasi Pelapor',
                    icon: LucideIcons.user,
                    accentColor: AppTheme.primaryColor,
                    children: [
                      _buildInfoRow(
                        LucideIcons.user,
                        'Nama',
                        widget.report.reporterName,
                      ),
                      if (widget.report.reporterEmail != null)
                        _buildInfoRow(
                          LucideIcons.mail,
                          'Email',
                          widget.report.reporterEmail!,
                        ),
                      if (widget.report.reporterPhone != null)
                        _buildInfoRowWithAction(
                          LucideIcons.phone,
                          'Telepon',
                          widget.report.reporterPhone!,
                          onTap: () =>
                              _launchPhone(widget.report.reporterPhone),
                        ),
                    ],
                  ),
                  const Gap(16),

                  // Handled By (Visible to Everyone if assigned)
                  if (widget.report.handledBy != null &&
                      widget.report.handledBy!.isNotEmpty) ...[
                    _buildInfoCard(
                      title: 'Ditangani Oleh',
                      icon: LucideIcons.wrench,
                      accentColor: AppTheme.secondaryColor,
                      children: widget.report.handledBy!
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
                  if (widget.report.supervisorName != null) ...[
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
                                widget.report.supervisorName!,
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
                  if (widget.report.handlingStartedAt != null &&
                      widget.report.completedAt != null) ...[
                    _buildInfoCard(
                      title: 'Waktu Penanganan',
                      icon: LucideIcons.timer,
                      accentColor: Colors.green,
                      children: [
                        // Total handling time
                        () {
                          final totalTime = widget.report.completedAt!
                              .difference(widget.report.handlingStartedAt!);
                          final holdDuration = Duration(
                            seconds: widget.report.totalPausedDurationSeconds,
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
                                _formatDateTime(
                                  widget.report.handlingStartedAt!,
                                ),
                              ),
                              // Completed At
                              _buildInfoRow(
                                LucideIcons.checkCircle2,
                                'Selesai Dikerjakan',
                                _formatDateTime(widget.report.completedAt!),
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
                        LucideIcons.mapPin,
                        'Tempat',
                        widget.report.location,
                      ),
                      if (widget.report.locationDetail != null &&
                          widget.report.locationDetail!.isNotEmpty)
                        _buildInfoRow(
                          LucideIcons.mapPin,
                          'Detail Lokasi',
                          widget.report.locationDetail!,
                        ),
                      const Gap(12),
                      _buildMapPreview(
                        context,
                        latitude:
                            _liveLatLng?.latitude ??
                            widget.report.latitude ??
                            -6.998576,
                        longitude:
                            _liveLatLng?.longitude ??
                            widget.report.longitude ??
                            110.423188,
                      ),
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
                        widget.report.description,
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
                        logs: () {
                          // Create a mutable copy of logs
                          final allLogs = List<ReportLog>.from(_logs);

                          // Check if "created" action already exists
                          final hasCreatedLog = allLogs.any(
                            (log) => log.action == ReportAction.created,
                          );

                          // If not, add a synthetic one based on report.createdAt
                          if (!hasCreatedLog) {
                            allLogs.add(
                              ReportLog(
                                id: 'created_${widget.report.id}',
                                fromStatus: ReportStatus.pending,
                                toStatus: ReportStatus.pending,
                                action: ReportAction.created,
                                actorId: widget.report.reporterId,
                                actorName: widget.report.reporterName,
                                actorRole: 'Pelapor',
                                timestamp: widget.report.createdAt,
                              ),
                            );
                          }

                          // Sort by timestamp descending (Newest first)
                          allLogs.sort(
                            (a, b) => b.timestamp.compareTo(a.timestamp),
                          );

                          return allLogs;
                        }(),
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
      bottomNavigationBar: widget.actionButtons != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: widget.actionButtons!
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
    final statusColor = AppTheme.getStatusColor(widget.report.status.name);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: statusColor,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
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
            // 1. Base Color
            Container(color: statusColor),

            // 2. Pattern Overlay
            CustomPaint(
              painter: _PatternPainter(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),

            // 3. Large Watermark Icon (Category/Status)
            Positioned(
              right: -40,
              bottom: -20,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  AppTheme.getStatusIcon(widget.report.status.name),
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),

            // 4. Gradient Overlay for Text Readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black45],
                ),
              ),
            ),

            // 5. Title and Category
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge: Emergency OR Category
                  if (widget.report.isEmergency)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.emergencyColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
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
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        widget.report.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Gap(12),
                  Text(
                    widget.report.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
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
    final statusColor = AppTheme.getStatusColor(widget.report.status.name);
    final statusIcon = AppTheme.getStatusIcon(widget.report.status.name);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Laporan',
                style: TextStyle(
                  color: statusColor.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              const Gap(4),
              Text(
                widget.report.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
            color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildMapPreview(
    BuildContext context, {
    required double latitude,
    required double longitude,
  }) {
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
                  initialCenter: LatLng(latitude, longitude),
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
                        point: LatLng(latitude, longitude),
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
                      latitude: latitude,
                      longitude: longitude,
                      locationName: widget.report.location,
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

class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double spacing = 30; // Spacing between lines

    // Draw diagonal lines
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
