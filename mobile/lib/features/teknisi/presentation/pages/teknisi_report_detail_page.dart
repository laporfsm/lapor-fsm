import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
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
          'isEmergency': false,
          'status': 'pending', // pending, verifikasi, penanganan, selesai
          'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
          'reporterName': 'Ahmad Fauzi',
          'reporterPhone': '08123456789',
          'reporterEmail': 'ahmad.fauzi@students.undip.ac.id',
          'logs': [
            {
              'action': 'created',
              'time': DateTime.now().subtract(const Duration(minutes: 30)),
              'notes': 'Laporan dibuat',
            },
          ],
        };
        _isLoading = false;
      });
    });
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
                      // Map preview placeholder
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.map,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                  const Gap(8),
                                  Text(
                                    'Lat: ${_report['latitude']}, Long: ${_report['longitude']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: ElevatedButton.icon(
                                onPressed: () => _openMaps(
                                  _report['latitude'],
                                  _report['longitude'],
                                ),
                                icon: const Icon(
                                  LucideIcons.navigation,
                                  size: 14,
                                ),
                                label: const Text('Buka Maps'),
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

                  // Activity Log Card
                  _buildInfoCard(
                    title: 'Riwayat Aktivitas',
                    icon: LucideIcons.clock,
                    children: [
                      ...(_report['logs'] as List).map(
                        (log) => _buildLogItem(log),
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
        statusColor = Colors.grey;
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
          if (status == 'penanganan')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.timer, color: Colors.white, size: 14),
                  Gap(4),
                  Text(
                    '15:30',
                    style: TextStyle(
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

  Widget _buildLogItem(Map<String, dynamic> log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['notes'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Gap(2),
                Text(
                  _formatDateTime(log['time']),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
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
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _verifyReport,
                  icon: const Icon(LucideIcons.checkCircle),
                  label: const Text('Verifikasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            if (status == 'verifikasi') ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startHandling,
                  icon: const Icon(LucideIcons.play),
                  label: const Text('Mulai Penanganan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
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

  void _verifyReport() {
    // TODO: Call API to verify report
    setState(() {
      _report['status'] = 'verifikasi';
      (_report['logs'] as List).insert(0, {
        'action': 'verified',
        'time': DateTime.now(),
        'notes': 'Laporan diverifikasi oleh Teknisi',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan berhasil diverifikasi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _startHandling() {
    // TODO: Call API to start handling
    setState(() {
      _report['status'] = 'penanganan';
      (_report['logs'] as List).insert(0, {
        'action': 'handling',
        'time': DateTime.now(),
        'notes': 'Teknisi mulai menangani laporan',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Penanganan dimulai - Timer berjalan'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
