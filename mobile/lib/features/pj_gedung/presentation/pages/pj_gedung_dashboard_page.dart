import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/enums/report_status.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/core/models/report.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/report_card.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_report_detail_page.dart';

class PJGedungDashboardPage extends StatefulWidget {
  const PJGedungDashboardPage({super.key});

  @override
  State<PJGedungDashboardPage> createState() => _PJGedungDashboardPageState();
}

class _PJGedungDashboardPageState extends State<PJGedungDashboardPage> {
  bool _isLoading = true;
  List<Report> _reports = [];
  Timer? _refreshTimer;
  String _activeFilter = 'pending'; // 'pending' or 'verified'

  // Mock Data for statistics
  int _verifiedToday = 12;

  @override
  void initState() {
    super.initState();
    _fetchReports();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _fetchReports(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchReports({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // FETCH REAL DATA (Mocked for now)
    final reportsData = await reportService.getPublicReports(
      status: ReportStatus.pending.name,
    );

    // MOCK DATA GENERATION
    final mockPendingReports = [
      Report(
        id: 'mock-pj-1',
        title: 'AC Bocor di Ruang Sidang',
        description: 'Air menetes cukup deras, membasahi karpet.',
        category: 'Fasilitas Umum',
        building: 'Gedung A, Lt 2',
        status: ReportStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        reporterId: 'r1',
        reporterName: 'Budi Mahasiswa',
        isEmergency: false,
      ),
      Report(
        id: 'mock-pj-2',
        title: 'Lampu Koridor Kedip-kedip',
        description: 'Sangat mengganggu saat lewat.',
        category: 'Kelistrikan',
        building: 'Gedung B, Lt 1',
        status: ReportStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        reporterId: 'r2',
        reporterName: 'Siti Staff',
        isEmergency: false,
      ),
      Report(
        id: 'mock-pj-3',
        title: 'Kran Air Patah',
        description: 'Air muncrat terus menerus.',
        category: 'Sanitasi',
        building: 'Gedung C, Toilet Pria',
        status: ReportStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        reporterId: 'r3',
        reporterName: 'Ahmad Dosen',
        isEmergency: false,
      ),
    ];

    final mockVerifiedReports = [
      Report(
        id: 'mock-pj-v1',
        title: 'Proyektor Buram',
        description: 'Lensa kotor atau rusak.',
        category: 'Fasilitas Kelas',
        building: 'Gedung A, R. 204',
        status: ReportStatus.verifikasi, // Verified, but not yet handled
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        reporterId: 'r4',
        reporterName: 'Dosen A',
        isEmergency: false,
      ),
      Report(
        id: 'mock-pj-v2',
        title: 'Pintu Lift Macet',
        description: 'Kadang tidak mau terbuka.',
        category: 'Sipil',
        building: 'Gedung B, Lt Dasar',
        status: ReportStatus.verifikasi,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        reporterId: 'r5',
        reporterName: 'Satpam',
        isEmergency: false,
      ),
    ];

    // Combine real + mock
    final allPending = [
      ...reportsData.map((e) => Report.fromJson(e)),
      ...mockPendingReports,
    ];

    // Filter logic
    final displayedReports = _activeFilter == 'pending'
        ? allPending
        : mockVerifiedReports; // Use mock verified for demo

    if (mounted) {
      setState(() {
        _reports = displayedReports.cast<Report>();
        _isLoading = false;
        // Update stats
        if (_activeFilter == 'verified') {
          _verifiedToday = _reports.length + 10; // Mock count
        }
      });
    }
  }

  void _navigateToDetail(Report report) async {
    // Navigate to detail page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PJGedungReportDetailPage(report: report),
      ),
    );

    // If result is true (verified/action taken), refresh list
    if (result == true) {
      _fetchReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Dashboard PJ Gedung',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Realtime indicator instead of refresh button
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.radio, size: 14, color: Colors.green),
                  Gap(4),
                  Text(
                    "Realtime",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Section (Fixed Header)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Hari Ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeFilter = 'pending';
                            _fetchReports();
                          });
                        },
                        child: _buildStatCard(
                          'Perlu Verifikasi',
                          '3', // Mock static for now, or match list length
                          LucideIcons.clipboardList,
                          const Color(0xFFF59E0B),
                          isActive: _activeFilter == 'pending',
                        ),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeFilter = 'verified';
                            _fetchReports();
                          });
                        },
                        child: _buildStatCard(
                          'Terverifikasi',
                          _verifiedToday.toString(),
                          LucideIcons.checkCircle,
                          const Color(0xFF10B981),
                          isActive: _activeFilter == 'verified',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _activeFilter == 'pending'
                          ? 'Menunggu Verifikasi'
                          : 'Terverifikasi Baru Ini',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _activeFilter == 'pending'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _reports.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Report List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _fetchReports(),
                    child: _reports.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _reports.length,
                            separatorBuilder: (c, i) => const Gap(16),
                            itemBuilder: (context, index) {
                              final report = _reports[index];
                              return ReportCard(
                                report: report,
                                viewerRole: UserRole.pjGedung,
                                actionLabel: _activeFilter == 'pending'
                                    ? "Verifikasi"
                                    : "Lihat Detail",
                                onAction: () => _navigateToDetail(report),
                                onTap: () => _navigateToDetail(report),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isActive = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? color.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive ? color : Colors.grey.shade200,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              LucideIcons.checkCircle,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const Gap(16),
            Text(
              "Tidak ada laporan dalam kategori ini",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
