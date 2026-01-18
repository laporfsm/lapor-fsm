import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_history_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_profile_page.dart';

class TeknisiHomePage extends StatefulWidget {
  const TeknisiHomePage({super.key});

  @override
  State<TeknisiHomePage> createState() => _TeknisiHomePageState();
}

class _TeknisiHomePageState extends State<TeknisiHomePage> {
  int _currentIndex = 0;
  String _selectedCategory = 'all';
  final List<String> _categories = ['all', 'Kelistrikan', 'Sanitasi / Air', 'Sipil & Bangunan', 'K3 Lab'];
  Timer? _timer;

  // TODO: [BACKEND] Replace with API call to fetch pending reports
  final List<Map<String, dynamic>> _pendingReports = [
    {
      'id': 1,
      'title': 'AC Mati di Lab Komputer',
      'category': 'Kelistrikan',
      'building': 'Gedung G, Lt 2',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 10)),
      'isEmergency': false,
      'reporterName': 'Ahmad Fauzi',
      'reporterPhone': '08123456789',
    },
    {
      'id': 2,
      'title': 'Kebocoran Pipa Toilet',
      'category': 'Sanitasi / Air',
      'building': 'Gedung C, Lt 1',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
      'isEmergency': false,
      'reporterName': 'Siti Aminah',
      'reporterPhone': '08234567890',
    },
    {
      'id': 3,
      'title': 'Kecelakaan di Lab Kimia',
      'category': 'K3 Lab',
      'building': 'Gedung D, Lt 3',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 2)),
      'isEmergency': true,
      'reporterName': 'Budi Santoso',
      'reporterPhone': '08345678901',
    },
    {
      'id': 5,
      'title': 'Kebakaran Kecil di Kantin',
      'category': 'K3 Lab',
      'building': 'Kantin Utama',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 5)),
      'isEmergency': true,
      'reporterName': 'Dewi Lestari',
      'reporterPhone': '08456789012',
    },
  ];

  // TODO: [BACKEND] Replace with API call to fetch technician's active reports
  final List<Map<String, dynamic>> _myReports = [
    {
      'id': 4,
      'title': 'Lampu Koridor Mati',
      'category': 'Kelistrikan',
      'building': 'Gedung A, Lt 1',
      'status': 'penanganan',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 45)),
      'startedAt': DateTime.now().subtract(const Duration(minutes: 15)),
      'handledBy': ['Budi Santoso'], // Single technician
    },
    {
      'id': 6,
      'title': 'AC Rusak di Ruang Rapat',
      'category': 'Kelistrikan',
      'building': 'Gedung B, Lt 2',
      'status': 'penanganan',
      'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
      'startedAt': DateTime.now().subtract(const Duration(minutes: 30)),
      'handledBy': ['Budi Santoso', 'Ahmad Hidayat'], // Multiple technicians
    },
  ];

  // Filter reports by emergency status
  List<Map<String, dynamic>> get _emergencyReports =>
      _pendingReports.where((r) => r['isEmergency'] == true).toList();

  // Filtered by category
  List<Map<String, dynamic>> get _filteredRegularReports {
    if (_selectedCategory == 'all') return _regularReports;
    return _regularReports.where((r) => r['category'] == _selectedCategory).toList();
  }

  List<Map<String, dynamic>> get _regularReports =>
      _pendingReports.where((r) => r['isEmergency'] != true).toList();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Helper to format handledBy (can be String or List<String>)
  String _formatHandledBy(dynamic handledBy) {
    if (handledBy is List) {
      return handledBy.join(', ');
    }
    return handledBy.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Laporan Umum (Regular reports)
          _buildReportsPage(
            title: 'Laporan Umum',
            reports: _filteredRegularReports,
            emptyMessage: 'Tidak ada laporan umum',
            emptyIcon: LucideIcons.inbox,
            showCategoryFilter: true,
          ),
          // Tab 1: Laporan Darurat (Emergency reports)
          _buildReportsPage(
            title: 'Laporan Darurat',
            reports: _emergencyReports,
            emptyMessage: 'Tidak ada laporan darurat',
            emptyIcon: LucideIcons.siren,
            isEmergencyTab: true,
          ),
          // Tab 2: Dikerjakan (Active reports)
          _buildReportsPage(
            title: 'Sedang Dikerjakan',
            reports: _myReports,
            emptyMessage: 'Tidak ada laporan yang sedang dikerjakan',
            emptyIcon: LucideIcons.wrench,
            isActiveTab: true,
          ),
          // Tab 3: Riwayat
          const TeknisiHistoryPage(),
          // Tab 4: Profil
          const TeknisiProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.secondaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.inbox),
            label: 'Umum',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _emergencyReports.isNotEmpty,
              label: Text(_emergencyReports.length.toString()),
              backgroundColor: AppTheme.emergencyColor,
              child: const Icon(LucideIcons.siren),
            ),
            label: 'Darurat',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _myReports.isNotEmpty,
              label: Text(_myReports.length.toString()),
              backgroundColor: AppTheme.secondaryColor,
              child: const Icon(LucideIcons.wrench),
            ),
            label: 'Aktif',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.history),
            label: 'Riwayat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildReportsPage({
    required String title,
    required List<Map<String, dynamic>> reports,
    required String emptyMessage,
    required IconData emptyIcon,
    bool isEmergencyTab = false,
    bool isActiveTab = false,
    bool showCategoryFilter = false,
  }) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: isEmergencyTab
            ? AppTheme.emergencyColor
            : Colors.white,
        foregroundColor: isEmergencyTab ? Colors.white : Colors.black,
        automaticallyImplyLeading: false,
        // Reload icon removed - data will be real-time
      ),
      body: reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, size: 64, color: Colors.grey.shade300),
                  const Gap(16),
                  Text(
                    emptyMessage,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // TODO: [BACKEND] Refresh data from API
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _buildReportCard(
                    report,
                    isPending: !isActiveTab,
                    showEmergencyBanner: isEmergencyTab,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildReportCard(
    Map<String, dynamic> report, {
    required bool isPending,
    bool showEmergencyBanner = false,
  }) {
    final bool isEmergency = report['isEmergency'] ?? false;
    final Color statusColor = isEmergency
        ? AppTheme.emergencyColor
        : AppTheme.primaryColor;
    final DateTime createdAt = report['createdAt'] as DateTime;
    final Duration elapsed = DateTime.now().difference(createdAt);

    return GestureDetector(
      onTap: () {
        context.push('/teknisi/report/${report['id']}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isEmergency && showEmergencyBanner
              ? Border.all(color: AppTheme.emergencyColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isEmergency && showEmergencyBanner
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
            if (isEmergency && showEmergencyBanner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.emergencyColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      color: Colors.white,
                      size: 16,
                    ),
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
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Timer
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          report['category'],
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildTimer(elapsed, isEmergency: isEmergency),
                    ],
                  ),
                  const Gap(10),

                  // Title
                  Text(
                    report['title'],
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
                          report['building'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Handled by info (for active reports)
                  if (!isPending && report['handledBy'] != null) ...[
                    const Gap(8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const Gap(6),
                        Expanded(
                          child: Text(
                            'Ditangani oleh: ${_formatHandledBy(report['handledBy'])}',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (isPending) ...[
                    const Gap(8),
                    // Reporter info
                    Row(
                      children: [
                        Icon(
                          LucideIcons.user,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const Gap(6),
                        Text(
                          report['reporterName'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(12),
                        Icon(
                          LucideIcons.phone,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const Gap(6),
                        Text(
                          report['reporterPhone'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Gap(12),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/teknisi/report/${report['id']}');
                      },
                      icon: Icon(
                        isPending
                            ? LucideIcons.eye
                            : LucideIcons.clipboardCheck,
                        size: 18,
                      ),
                      label: Text(isPending ? 'Lihat Detail' : 'Selesaikan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPending
                            ? (isEmergency
                                  ? AppTheme.emergencyColor
                                  : AppTheme.primaryColor)
                            : const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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

  Widget _buildTimer(Duration elapsed, {bool isEmergency = false}) {
    Color timerColor = AppTheme.secondaryColor;
    if (elapsed.inMinutes >= 30) {
      timerColor = Colors.red;
    } else if (elapsed.inMinutes >= 15) {
      timerColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer, size: 14, color: timerColor),
          const Gap(4),
          Text(
            _formatDuration(elapsed),
            style: TextStyle(
              color: timerColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
