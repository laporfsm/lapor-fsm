import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SupervisorReviewPage extends StatefulWidget {
  final String reportId;
  const SupervisorReviewPage({super.key, required this.reportId});

  @override
  State<SupervisorReviewPage> createState() => _SupervisorReviewPageState();
}

class _SupervisorReviewPageState extends State<SupervisorReviewPage> {
  // Mock Data
  late Map<String, dynamic> _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _report = {
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
            'status': 'selesai',
            'isEmergency': false,
            'reporterName': 'Ahmad Fauzi',
            'reporterEmail': 'ahmad.fauzi@students.undip.ac.id',
            'reporterPhone': '08123456789',
            'handledBy': ['Budi Santoso'],
            'logs': [
              {
                'action': 'Selesai',
                'time': '10:30',
                'date': '17 Jan 2024',
                'notes': 'AC sudah diperbaiki, kapasitor diganti.',
                'isDone': true,
              },
              {
                'action': 'Penanganan',
                'time': '09:45',
                'date': '17 Jan 2024',
                'notes': 'Mulai pengecekan unit AC.',
                'isDone': true,
              },
              {
                'action': 'Verifikasi',
                'time': '09:00',
                'date': '17 Jan 2024',
                'notes': 'Laporan diterima supervisor.',
                'isDone': true,
              },
              {
                'action': 'Laporan Masuk',
                'time': '08:45',
                'date': '17 Jan 2024',
                'notes': 'Laporan dibuat oleh Ahmad Fauzi.',
                'isDone': true,
              },
            ],
          };
          _isLoading = false;
        });
      }
    });
  }

  void _launchPhone(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isEmergency = _report['isEmergency'];
    final String status = _report['status'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppTheme.supervisorColor,
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
                          color: Colors.red,
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

          // 2. Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  _buildStatusCard(status),
                  const Gap(16),

                  // Reporter Info Wrapper in Card
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
                  const Gap(16),

                  // Technician Info (if assigned)
                  if (_report['handledBy'] != null) ...[
                    _buildInfoCard(
                      title: 'Ditangani Oleh',
                      icon: LucideIcons.wrench,
                      children: [
                        ...(_report['handledBy'] as List<dynamic>).map(
                          (tech) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.user,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                ),
                                const Gap(12),
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

                  // Location Card with Map
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
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Map action - create route if needed
                                  },
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

                  // Activity Log Card (Timeline)
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

                  const Gap(100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Reject Action
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tolak Laporan'),
              ),
            ),
            const Gap(16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Verify/Accept Action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.supervisorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Verifikasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.grey;
        label = 'Menunggu';
        icon = LucideIcons.clock;
        break;
      case 'verifikasi':
        color = Colors.blue;
        label = 'Perlu Verifikasi';
        icon = LucideIcons.checkCircle2;
        break;
      case 'penanganan':
        color = Colors.orange;
        label = 'Sedang Dikerjakan';
        icon = LucideIcons.wrench;
        break;
      case 'selesai':
        color = Colors.green;
        label = 'Selesai';
        icon = LucideIcons.checkCheck;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = LucideIcons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Laporan',
                style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color,
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
              Icon(icon, size: 18, color: AppTheme.supervisorColor),
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
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppTheme.supervisorColor
                      : Colors.grey.shade300,
                  border: isFirst
                      ? Border.all(color: AppTheme.supervisorColor, width: 3)
                      : null,
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade200),
                ),
            ],
          ),
          const Gap(16),
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
                        log['action'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${log['time']} • ${log['date']}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    log['notes'], // Changed from 'note' to 'notes' to match mock data
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
