import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/theme.dart';

/// PJ Gedung theme color
const Color pjGedungColor = Color(0xFF059669); // Emerald green

class PJGedungDashboardPage extends StatefulWidget {
  const PJGedungDashboardPage({super.key});

  @override
  State<PJGedungDashboardPage> createState() => _PJGedungDashboardPageState();
}

class _PJGedungDashboardPageState extends State<PJGedungDashboardPage> {
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Mock Stats
  Map<String, int> get _stats => {
    'todayReports': 5,
    'weekReports': 18,
    'monthReports': 42,
    'pending': 3,
    'verified': 12,
    'rejected': 2,
  };

  // Mock Pending Reports (NON-emergency - these need PJ verification)
  List<Report> get _pendingReports => [
    Report(
      id: 'pj-1',
      title: 'AC Bocor di Ruang Sidang',
      description: 'Air menetes cukup deras.',
      category: 'Fasilitas Umum',
      building: 'Gedung A, Lt 2',
      status: ReportStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      reporterId: 'r1',
      reporterName: 'Budi Mahasiswa',
      isEmergency: false,
    ),
    Report(
      id: 'pj-2',
      title: 'Lampu Koridor Kedip-kedip',
      description: 'Sangat mengganggu.',
      category: 'Kelistrikan',
      building: 'Gedung A, Lt 1',
      status: ReportStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      reporterId: 'r2',
      reporterName: 'Siti Staff',
      isEmergency: false,
    ),
  ];

  // Mock Emergency Reports (view-only - handled directly by Supervisor)
  List<Report> get _emergencyReports => [
    Report(
      id: 'pj-e1',
      title: 'Kran Air Patah - Air Muncrat',
      description: 'Air muncrat terus menerus, perlu ditangani segera.',
      category: 'Sanitasi',
      building: 'Gedung A, Toilet Pria',
      status: ReportStatus.penanganan, // Already being handled by Supervisor
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      reporterId: 'r3',
      reporterName: 'Ahmad Dosen',
      isEmergency: true,
    ),
  ];

  // Mock Verified Reports
  List<Report> get _verifiedReports => [
    Report(
      id: 'pj-v1',
      title: 'Proyektor Buram',
      description: 'Lensa kotor.',
      category: 'Fasilitas Kelas',
      building: 'Gedung A, R. 204',
      status: ReportStatus.terverifikasi,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      reporterId: 'r4',
      reporterName: 'Dosen A',
      isEmergency: false,
    ),
    Report(
      id: 'pj-v2',
      title: 'Pintu Lift Macet',
      description: 'Kadang tidak terbuka.',
      category: 'Sipil',
      building: 'Gedung A, Lt Dasar',
      status: ReportStatus.terverifikasi,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      reporterId: 'r5',
      reporterName: 'Satpam',
      isEmergency: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: pjGedungColor,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Image.network(
                      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=1000',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: pjGedungColor),
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            pjGedungColor.withOpacity(0.85),
                            pjGedungColor.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    LucideIcons.building2,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const Gap(14),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dashboard PJ Gedung',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Gap(2),
                                    Text(
                                      'Verifikasi & Monitoring Gedung A',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emergency Alert Banner (view-only awareness)
                      if (_emergencyReports.isNotEmpty) ...[
                        _buildEmergencyAlert(context),
                        const Gap(16),
                      ],
                      _buildPeriodStats(context),
                      const Gap(16),
                      _buildStatusStats(context),
                      const Gap(16),
                      _buildQuickActions(context),
                      const Gap(24),
                      _buildSectionHeader(
                        context,
                        'Perlu Verifikasi',
                        'Lihat Semua',
                        () => context.push('/pj-gedung/reports?status=pending'),
                      ),
                      const Gap(12),
                      _buildPendingList(context),
                      const Gap(24),
                      _buildSectionHeader(
                        context,
                        'Terverifikasi Terbaru',
                        'Lihat Semua',
                        () => context.push(
                          '/pj-gedung/reports?status=terverifikasi',
                        ),
                      ),
                      const Gap(12),
                      _buildVerifiedList(context),
                      const Gap(32),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExportOptions(context),
        backgroundColor: Colors.white,
        child: const Icon(LucideIcons.download, color: pjGedungColor),
      ),
    );
  }

  /// Emergency Alert Banner - View Only (reports handled by Supervisor)
  Widget _buildEmergencyAlert(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade800],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laporan Darurat di Gedung Anda',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_emergencyReports.length} laporan ditangani langsung oleh Supervisor',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          // Show emergency reports list (compact)
          ..._emergencyReports
              .take(2)
              .map(
                (report) => Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              '${report.building} • ${report.status.label}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'View Only',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPeriodStats(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          context,
          'Hari Ini',
          _stats['todayReports'].toString(),
          LucideIcons.calendar,
          Colors.blue,
          'today',
        ),
        const Gap(12),
        _buildStatCard(
          context,
          'Minggu Ini',
          _stats['weekReports'].toString(),
          LucideIcons.calendarDays,
          Colors.green,
          'week',
        ),
        const Gap(12),
        _buildStatCard(
          context,
          'Bulan Ini',
          _stats['monthReports'].toString(),
          LucideIcons.calendarRange,
          Colors.orange,
          'month',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String period,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push('/pj-gedung/reports?period=$period'),
        child: Container(
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
            children: [
              Icon(icon, color: color, size: 24),
              const Gap(8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Gap(4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStats(BuildContext context) {
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
          const Text(
            'Status Laporan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Gap(12),
          Row(
            children: [
              _buildStatusBadge(
                context,
                'Pending',
                _stats['pending']!,
                Colors.amber,
                'pending',
              ),
              const Gap(8),
              _buildStatusBadge(
                context,
                'Terverifikasi',
                _stats['verified']!,
                Colors.green,
                'terverifikasi',
              ),
              const Gap(8),
              _buildStatusBadge(
                context,
                'Ditolak',
                _stats['rejected']!,
                Colors.red,
                'ditolak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String label,
    int count,
    Color color,
    String status,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push('/pj-gedung/reports?status=$status'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              Text(label, style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pj-gedung/reports'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pjGedungColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.layoutList, color: pjGedungColor),
            const Gap(10),
            const Text(
              'Semua Laporan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: pjGedungColor,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String actionText,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: pjGedungColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                title.contains('Perlu')
                    ? _pendingReports.length.toString()
                    : _verifiedReports.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        TextButton(onPressed: onTap, child: Text(actionText)),
      ],
    );
  }

  Widget _buildPendingList(BuildContext context) {
    if (_pendingReports.isEmpty) {
      return _buildEmptyState('Tidak ada laporan menunggu verifikasi');
    }

    return Column(
      children: _pendingReports.take(3).map((report) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UniversalReportCard(
            id: report.id,
            title: report.title,
            location: report.building,
            category: report.category,
            status: report.status,
            isEmergency: report.isEmergency,
            elapsedTime: DateTime.now().difference(report.createdAt),
            showStatus: true,
            showTimer: true,
            compact: true,
            onTap: () => context.push(
              '/pj-gedung/report/${report.id}',
              extra: {'report': report},
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerifiedList(BuildContext context) {
    if (_verifiedReports.isEmpty) {
      return _buildEmptyState('Belum ada laporan terverifikasi');
    }

    return Column(
      children: _verifiedReports.take(3).map((report) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UniversalReportCard(
            id: report.id,
            title: report.title,
            location: report.building,
            category: report.category,
            status: report.status,
            elapsedTime: DateTime.now().difference(report.createdAt),
            showStatus: true,
            compact: true,
            onTap: () => context.push(
              '/pj-gedung/report/${report.id}',
              extra: {'report': report},
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.inbox, size: 40, color: Colors.grey.shade300),
            const Gap(8),
            Text(message, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Riwayat Verifikasi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              Text(
                'Unduh data riwayat verifikasi laporan.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const Gap(24),
              ListTile(
                leading: const Icon(
                  LucideIcons.fileSpreadsheet,
                  color: Colors.green,
                ),
                title: const Text('Export ke Excel (.xlsx)'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mengunduh Excel... (Mock)')),
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              const Gap(12),
              ListTile(
                leading: const Icon(LucideIcons.fileText, color: Colors.red),
                title: const Text('Export ke PDF (.pdf)'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mengunduh PDF... (Mock)')),
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
