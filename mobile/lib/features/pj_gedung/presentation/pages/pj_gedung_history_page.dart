import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/presentation/widgets/report_card.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_report_detail_page.dart';

class PJGedungHistoryPage extends StatefulWidget {
  final String initialFilter; // 'pending' or 'verified'

  const PJGedungHistoryPage({super.key, this.initialFilter = 'pending'});

  @override
  State<PJGedungHistoryPage> createState() => _PJGedungHistoryPageState();
}

class _PJGedungHistoryPageState extends State<PJGedungHistoryPage> {
  late String _activeFilter;
  bool _isLoading = true;
  List<Report> _reports = [];

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

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
        status: ReportStatus.terverifikasi,
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
        status: ReportStatus.terverifikasi,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        reporterId: 'r5',
        reporterName: 'Satpam',
        isEmergency: false,
      ),
    ];

    if (mounted) {
      setState(() {
        _reports = _activeFilter == 'pending'
            ? mockPendingReports
            : mockVerifiedReports;
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(Report report) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PJGedungReportDetailPage(report: report),
      ),
    );
    if (result == true) _fetchReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _activeFilter == 'pending' ? 'Perlu Verifikasi' : 'Terverifikasi',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter, color: Colors.black),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? const Center(child: Text("Tidak ada laporan"))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _reports.length,
              separatorBuilder: (c, i) => const Gap(16),
              itemBuilder: (context, index) {
                final report = _reports[index];
                return ReportCard(
                  report: report,
                  viewerRole: UserRole.pjGedung,
                  actionLabel: _activeFilter == 'pending'
                      ? "Verifikasi"
                      : "Lihat",
                  onAction: () => _navigateToDetail(report),
                  onTap: () => _navigateToDetail(report),
                );
              },
            ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Perlu Verifikasi'),
              trailing: _activeFilter == 'pending'
                  ? const Icon(LucideIcons.check, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _activeFilter = 'pending';
                  _fetchReports();
                });
              },
            ),
            ListTile(
              title: const Text('Terverifikasi'),
              trailing: _activeFilter == 'verified'
                  ? const Icon(LucideIcons.check, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _activeFilter = 'verified';
                  _fetchReports();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
