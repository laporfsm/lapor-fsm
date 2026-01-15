import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class TeknisiReportDetailPage extends StatefulWidget {
  final String reportId;

  const TeknisiReportDetailPage({super.key, required this.reportId});

  @override
  State<TeknisiReportDetailPage> createState() =>
      _TeknisiReportDetailPageState();
}

class _TeknisiReportDetailPageState extends State<TeknisiReportDetailPage> {
  // Mock data - will be replaced with API
  late Map<String, dynamic> _report;
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadReport();
    // TK-011: Timer for live counter
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadReport() {
    // TODO: [BACKEND] Replace with API call to fetch report details
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        final int reportIdNum = int.tryParse(widget.reportId) ?? 0;

        // Check report type based on ID
        // IDs 101-103: Completed reports (from Riwayat Aktivitas)
        // IDs 4, 6: Active reports (from Sedang Dikerjakan)
        // Other IDs: Pending reports (from Laporan Umum)

        if (reportIdNum >= 101 && reportIdNum <= 103) {
          _report = _getCompletedReportData(reportIdNum);
        } else if (reportIdNum == 4 || reportIdNum == 6) {
          _report = _getActiveReportData(reportIdNum);
        } else {
          _report = _getPendingReportData();
        }
        _isLoading = false;
      });
    });
  }

  // Mock data for ACTIVE reports (from Sedang Dikerjakan tab)
  Map<String, dynamic> _getActiveReportData(int reportId) {
    final activeReports = {
      4: {
        'id': '4',
        'title': 'Lampu Koridor Mati',
        'description':
            'Lampu di koridor lantai 1 mati semua. Sudah dicoba ganti lampu tapi tetap tidak menyala.',
        'category': 'Kelistrikan',
        'building': 'Gedung A, Lt 1',
        'latitude': -6.9940,
        'longitude': 110.4210,
        'imageUrl':
            'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
        'isEmergency': false,
        'status': 'penanganan',
        'createdAt': DateTime.now().subtract(const Duration(minutes: 45)),
        'reporterName': 'Rudi Hartono',
        'reporterPhone': '08345678901',
        'reporterEmail': 'rudi.hartono@students.undip.ac.id',
        'handledBy': ['Budi Santoso'],
        'logs': [
          {
            'action': 'penanganan',
            'time': DateTime.now().subtract(const Duration(minutes: 15)),
            'notes': 'Teknisi mulai menangani laporan',
            'isDone': true,
          },
          {
            'action': 'verifikasi',
            'time': DateTime.now().subtract(const Duration(minutes: 30)),
            'notes': 'Laporan diverifikasi dan ditangani',
            'isDone': true,
          },
          {
            'action': 'created',
            'time': DateTime.now().subtract(const Duration(minutes: 45)),
            'notes': 'Laporan dibuat oleh Rudi Hartono',
            'isDone': true,
          },
        ],
      },
      6: {
        'id': '6',
        'title': 'AC Rusak di Ruang Rapat',
        'description':
            'AC di ruang rapat tidak bisa dingin. Sudah di-setting ke suhu rendah tapi tetap panas.',
        'category': 'Kelistrikan',
        'building': 'Gedung B, Lt 2',
        'latitude': -6.9935,
        'longitude': 110.4205,
        'imageUrl':
            'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
        'isEmergency': false,
        'status': 'penanganan',
        'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
        'reporterName': 'Dewi Lestari',
        'reporterPhone': '08456789012',
        'reporterEmail': 'dewi.lestari@students.undip.ac.id',
        'handledBy': ['Budi Santoso', 'Ahmad Hidayat'],
        'logs': [
          {
            'action': 'penanganan',
            'time': DateTime.now().subtract(const Duration(minutes: 30)),
            'notes': 'Teknisi mulai menangani laporan',
            'isDone': true,
          },
          {
            'action': 'verifikasi',
            'time': DateTime.now().subtract(const Duration(minutes: 45)),
            'notes': 'Laporan diverifikasi dan ditangani',
            'isDone': true,
          },
          {
            'action': 'created',
            'time': DateTime.now().subtract(const Duration(hours: 1)),
            'notes': 'Laporan dibuat oleh Dewi Lestari',
            'isDone': true,
          },
        ],
      },
    };
    return activeReports[reportId] ?? _getPendingReportData();
  }

  Map<String, dynamic> _getCompletedReportData(int reportId) {
    final completedReports = {
      101: {
        'id': '101',
        'title': 'AC Mati di Lab Komputer',
        'description':
            'AC di Lab Komputer ruang 201 tidak menyala sejak pagi. Sudah dicoba restart tapi tetap tidak berfungsi. Suhu ruangan sangat panas.',
        'category': 'Kelistrikan',
        'building': 'Gedung G, Lt 2, Ruang 201',
        'latitude': -6.9932,
        'longitude': 110.4203,
        'imageUrl':
            'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
        'isEmergency': false,
        'status': 'selesai',
        'createdAt': DateTime.now().subtract(const Duration(days: 4)),
        'reporterName': 'Ahmad Fauzi',
        'reporterPhone': '08123456789',
        'reporterEmail': 'ahmad.fauzi@students.undip.ac.id',
        'handledBy': ['Budi Santoso'],
        'supervisedBy': 'Pak Joko Widodo',
        'logs': [
          {
            'action': 'selesai',
            'time': DateTime.now().subtract(const Duration(days: 4, hours: -1)),
            'notes': 'Laporan selesai ditangani',
            'photoUrl':
                'https://images.unsplash.com/photo-1581092921461-eab32e97f6d3?w=400',
            'isDone': true,
          },
          {
            'action': 'penanganan',
            'time': DateTime.now().subtract(const Duration(days: 4, hours: 1)),
            'notes': 'Teknisi mulai menangani laporan',
            'isDone': true,
          },
          {
            'action': 'verifikasi',
            'time': DateTime.now().subtract(const Duration(days: 4, hours: 2)),
            'notes': 'Laporan diverifikasi dan ditangani',
            'isDone': true,
          },
          {
            'action': 'created',
            'time': DateTime.now().subtract(const Duration(days: 4, hours: 3)),
            'notes': 'Laporan dibuat oleh Ahmad Fauzi',
            'isDone': true,
          },
        ],
      },
      102: {
        'id': '102',
        'title': 'Kebocoran Pipa Toilet',
        'description':
            'Pipa di toilet lantai 1 bocor dan menyebabkan genangan air. Perlu segera diperbaiki.',
        'category': 'Sipil & Bangunan',
        'building': 'Gedung E, Lt 1',
        'latitude': -6.9945,
        'longitude': 110.4215,
        'imageUrl':
            'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
        'isEmergency': false,
        'status': 'selesai',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'reporterName': 'Siti Aminah',
        'reporterPhone': '08234567890',
        'reporterEmail': 'siti.aminah@students.undip.ac.id',
        'handledBy': ['Budi Santoso', 'Ahmad Hidayat'],
        'supervisedBy': 'Pak Joko Widodo',
        'logs': [
          {
            'action': 'selesai',
            'time': DateTime.now().subtract(const Duration(days: 5, hours: -2)),
            'notes': 'Laporan selesai ditangani',
            'photoUrl':
                'https://images.unsplash.com/photo-1581092921461-eab32e97f6d3?w=400',
            'isDone': true,
          },
          {
            'action': 'penanganan',
            'time': DateTime.now().subtract(const Duration(days: 5, hours: 1)),
            'notes': 'Teknisi mulai menangani laporan',
            'isDone': true,
          },
          {
            'action': 'verifikasi',
            'time': DateTime.now().subtract(const Duration(days: 5, hours: 2)),
            'notes': 'Laporan diverifikasi dan ditangani',
            'isDone': true,
          },
          {
            'action': 'created',
            'time': DateTime.now().subtract(const Duration(days: 5, hours: 3)),
            'notes': 'Laporan dibuat oleh Siti Aminah',
            'isDone': true,
          },
        ],
      },
      103: {
        'id': '103',
        'title': 'Lampu Koridor Mati',
        'description':
            'Lampu di koridor lantai 3 mati semua sejak kemarin malam.',
        'category': 'Kelistrikan',
        'building': 'Gedung C, Lt 3',
        'latitude': -6.9950,
        'longitude': 110.4200,
        'imageUrl':
            'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
        'isEmergency': false,
        'status': 'selesai',
        'createdAt': DateTime.now().subtract(const Duration(days: 6)),
        'reporterName': 'Rudi Hartono',
        'reporterPhone': '08345678901',
        'reporterEmail': 'rudi.hartono@students.undip.ac.id',
        'handledBy': ['Ahmad Hidayat'],
        'supervisedBy': 'Pak Susilo',
        'logs': [
          {
            'action': 'selesai',
            'time': DateTime.now().subtract(const Duration(days: 6, hours: -1)),
            'notes': 'Laporan selesai ditangani',
            'photoUrl':
                'https://images.unsplash.com/photo-1581092921461-eab32e97f6d3?w=400',
            'isDone': true,
          },
          {
            'action': 'penanganan',
            'time': DateTime.now().subtract(const Duration(days: 6, hours: 1)),
            'notes': 'Teknisi mulai menangani laporan',
            'isDone': true,
          },
          {
            'action': 'verifikasi',
            'time': DateTime.now().subtract(const Duration(days: 6, hours: 2)),
            'notes': 'Laporan diverifikasi dan ditangani',
            'isDone': true,
          },
          {
            'action': 'created',
            'time': DateTime.now().subtract(const Duration(days: 6, hours: 3)),
            'notes': 'Laporan dibuat oleh Rudi Hartono',
            'isDone': true,
          },
        ],
      },
    };
    return completedReports[reportId] ?? _getPendingReportData();
  }

  Map<String, dynamic> _getPendingReportData() {
    return {
      'id': widget.reportId,
      'title': 'AC Mati di Lab Komputer',
      'description':
          'AC di Lab Komputer ruang 201 tidak menyala sejak pagi. Sudah dicoba restart tapi tetap tidak berfungsi. Suhu ruangan sangat panas.',
      'category': 'Kelistrikan',
      'building': 'Gedung G, Lt 2, Ruang 201',
      'latitude': -6.9932,
      'longitude': 110.4203,
      'imageUrl':
          'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
      'isEmergency': false,
      'status': 'pending',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
      'reporterName': 'Ahmad Fauzi',
      'reporterPhone': '08123456789',
      'reporterEmail': 'ahmad.fauzi@students.undip.ac.id',
      'handledBy': null,
      'logs': [
        {
          'action': 'created',
          'time': DateTime.now().subtract(const Duration(minutes: 30)),
          'notes': 'Laporan dibuat oleh Ahmad Fauzi',
          'isDone': true,
        },
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isEmergency = _report['isEmergency'] ?? false;
    final String status = _report['status'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
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
                  // Report Image
                  Image.network(
                    _report['imageUrl'],
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
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Emergency badge
                  if (isEmergency)
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
                  // Title at bottom
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
                            _report['category'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          _report['title'],
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
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  _buildStatusCard(status),
                  const Gap(16),

                  // Reporter Info Card
                  _buildInfoCard(
                    title: 'Informasi Pelapor',
                    icon: LucideIcons.user,
                    children: [
                      _buildInfoRow(
                        LucideIcons.user,
                        'Nama',
                        _report['reporterName'],
                      ),
                      _buildInfoRow(
                        LucideIcons.mail,
                        'Email',
                        _report['reporterEmail'],
                      ),
                      _buildInfoRowWithAction(
                        LucideIcons.phone,
                        'Telepon',
                        _report['reporterPhone'],
                        onTap: () => _launchPhone(_report['reporterPhone']),
                      ),
                    ],
                  ),
                  // Handled By Info (if report is being handled)
                  if (_report['handledBy'] != null) ...[
                    _buildInfoCard(
                      title: 'Ditangani Oleh',
                      icon: LucideIcons.users,
                      children: [
                        // Bug #5 Fix: Support multiple technicians as a list
                        ...(_report['handledBy'] as List<dynamic>).map(
                          (tech) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Gap(12),
                                Icon(
                                  LucideIcons.wrench,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    tech.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                  ],

                  // TK-013: Show Supervisor Info
                  if (_report['supervisedBy'] != null) ...[
                    _buildInfoCard(
                      title: 'Diverifikasi Oleh',
                      icon: LucideIcons.userCheck,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.secondaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Gap(12),
                              Icon(
                                LucideIcons.user,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  _report['supervisedBy'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                  ],

                  const Gap(16),

                  // Location Card
                  _buildInfoCard(
                    title: 'Lokasi',
                    icon: LucideIcons.mapPin,
                    children: [
                      _buildInfoRow(
                        LucideIcons.building,
                        'Gedung',
                        _report['building'],
                      ),
                      const Gap(12),
                      // Bug #1 Fix: Interactive Map Preview like Pelapor
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // FlutterMap preview (non-interactive)
                              IgnorePointer(
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                      _report['latitude'],
                                      _report['longitude'],
                                    ),
                                    initialZoom: 15,
                                    interactionOptions:
                                        const InteractionOptions(
                                          flags: InteractiveFlag.none,
                                        ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.laporfsm.mobile',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(
                                            _report['latitude'],
                                            _report['longitude'],
                                          ),
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
                              // Button to open interactive map
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push(
                                    '/teknisi/map',
                                    extra: {
                                      'latitude': _report['latitude'],
                                      'longitude': _report['longitude'],
                                      'locationName': _report['building'],
                                    },
                                  ),
                                  icon: const Icon(
                                    LucideIcons.maximize2,
                                    size: 14,
                                  ),
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
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Description Card
                  _buildInfoCard(
                    title: 'Deskripsi Laporan',
                    icon: LucideIcons.fileText,
                    children: [
                      Text(
                        _report['description'],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Activity Log Card - Bug #2 Fix: Timeline with connected dots
                  _buildInfoCard(
                    title: 'Riwayat Aktivitas',
                    icon: LucideIcons.clock,
                    children: [
                      ...(_report['logs'] as List).asMap().entries.map(
                        (entry) => _buildLogItem(
                          entry.value,
                          index: entry.key,
                          total: (_report['logs'] as List).length,
                        ),
                      ),
                    ],
                  ),

                  const Gap(100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Action Buttons
      bottomNavigationBar: _buildActionButtons(status),
    );
  }

  Widget _buildStatusCard(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = AppTheme.secondaryColor;
        statusText = 'Menunggu Verifikasi';
        statusIcon = LucideIcons.clock;
        break;
      case 'verifikasi':
        statusColor = Colors.blue;
        statusText = 'Terverifikasi';
        statusIcon = LucideIcons.checkCircle;
        break;
      case 'penanganan':
        statusColor = AppTheme.secondaryColor;
        statusText = 'Sedang Ditangani';
        statusIcon = LucideIcons.wrench;
        break;
      case 'penanganan_ulang':
        statusColor = Colors.orange;
        statusText = 'Penanganan Ulang';
        statusIcon = LucideIcons.refreshCw;
        break;
      case 'selesai':
        statusColor = Colors.green;
        statusText = 'Selesai';
        statusIcon = LucideIcons.checkCircle2;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = LucideIcons.helpCircle;
    }

    // TK-011: Calculate elapsed time from createdAt
    final DateTime createdAt = _report['createdAt'] as DateTime;
    final Duration elapsed = DateTime.now().difference(createdAt);
    final bool showTimer = status == 'pending' || status == 'penanganan';

    // Determine timer color based on elapsed time
    Color timerColor = AppTheme.secondaryColor;
    if (elapsed.inMinutes >= 30) {
      timerColor = Colors.red;
    } else if (elapsed.inMinutes >= 15) {
      timerColor = Colors.orange;
    }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Laporan',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // TK-011: Show timer for pending and penanganan status
          if (showTimer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: timerColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.timer, color: Colors.white, size: 14),
                  const Gap(4),
                  Text(
                    _formatDuration(elapsed),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // TK-011: Format duration for timer display
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
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
              Icon(icon, size: 18, color: AppTheme.primaryColor),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const Gap(8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const Gap(8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(
              LucideIcons.phone,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // Bug #2 Fix: Timeline with connected dots like Pelapor
  Widget _buildLogItem(
    Map<String, dynamic> log, {
    required int index,
    required int total,
  }) {
    final bool isDone = log['isDone'] ?? false;
    final bool isFirst = index == 0;
    final bool isLast = index == total - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column with dot and connecting line
          Column(
            children: [
              // Circle dot
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppTheme.primaryColor : Colors.grey.shade300,
                  border: isFirst
                      ? Border.all(color: AppTheme.primaryColor, width: 3)
                      : null,
                ),
                child: isDone
                    ? const Icon(
                        LucideIcons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              // Connecting line (hide for last item)
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const Gap(12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log['notes'],
                    style: TextStyle(
                      fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                      color: isDone ? Colors.black : Colors.grey,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    _formatDateTime(log['time']),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  // TK-014: Show photo in timeline log if available
                  if (log['photoUrl'] != null) ...[
                    const Gap(8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              Dialog(child: Image.network(log['photoUrl'])),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          log['photoUrl'],
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                LucideIcons.imageOff,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildActionButtons(String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (status == 'pending') ...[
              // Reject Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rejectReport,
                  icon: const Icon(LucideIcons.x),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const Gap(12),
              // Verify & Handle Button - combined action
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _verifyAndHandle,
                  icon: const Icon(LucideIcons.checkCircle),
                  label: const Text('Verifikasi & Tangani'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            if (status == 'penanganan' || status == 'penanganan_ulang') ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/teknisi/report/${widget.reportId}/complete',
                  ),
                  icon: const Icon(LucideIcons.checkCircle2),
                  label: const Text('Selesaikan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _verifyAndHandle() {
    // TODO: [BACKEND] Call API to verify and start handling
    setState(() {
      _report['status'] = 'penanganan';
      // Assign current technician(s) - can be multiple
      // TODO: [BACKEND] Get from logged in user
      _report['handledBy'] = ['Budi Santoso', 'Ahmad Hidayat'];
      (_report['logs'] as List).insert(0, {
        'action': 'handling',
        'time': DateTime.now(),
        'notes': 'Teknisi mulai menangani laporan',
        'isDone': true,
      });
      (_report['logs'] as List).insert(0, {
        'action': 'verified',
        'time': DateTime.now(),
        'notes': 'Laporan diverifikasi dan ditangani',
        'isDone': true,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan diverifikasi - Penanganan dimulai'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectReport() {
    // Show dialog to get rejection reason
    showDialog(
      context: context,
      builder: (context) {
        String reason = '';
        return AlertDialog(
          title: const Text('Tolak Laporan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan alasan penolakan:'),
              const Gap(12),
              TextField(
                onChanged: (value) => reason = value,
                decoration: const InputDecoration(
                  hintText: 'Alasan penolakan...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: [BACKEND] Call API to reject report and send back to Supervisor
                setState(() {
                  _report['status'] = 'ditolak';
                  (_report['logs'] as List).insert(0, {
                    'action': 'rejected',
                    'time': DateTime.now(),
                    'notes':
                        'Laporan ditolak: ${reason.isEmpty ? "Tidak ada alasan" : reason}',
                    'isDone': true,
                  });
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Laporan ditolak dan dikembalikan ke Supervisor',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                // Go back to home after rejection
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
