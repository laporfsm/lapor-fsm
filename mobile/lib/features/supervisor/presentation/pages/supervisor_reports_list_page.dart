import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:go_router/go_router.dart';

// Shared Report features
import '../../../report_common/domain/entities/report.dart';
import '../../../report_common/domain/enums/report_status.dart';
import '../../../report_common/presentation/widgets/report_card.dart';

class SupervisorReportsListPage extends StatefulWidget {
  final String? initialStatus;
  final String? initialPeriod;
  final bool showEmergencyOnly;
  final bool isTabMode; // New: to remove Scaffold/AppBar if inside tab
  final List<String>? filterStatuses; // New: specific statuses to show

  const SupervisorReportsListPage({
    super.key,
    this.initialStatus,
    this.initialPeriod,
    this.showEmergencyOnly = false,
    this.isTabMode = false,
    this.filterStatuses,
  });

  @override
  State<SupervisorReportsListPage> createState() =>
      _SupervisorReportsListPageState();
}

class _SupervisorReportsListPageState extends State<SupervisorReportsListPage> {
  // Mock data as Report objects
  final List<Report> _allReports = [
    Report(
      id: '1',
      title: 'AC Mati di Lab Komputer',
      description: 'AC tidak dingin sama sekali',
      category: 'Kelistrikan',
      building: 'Gedung G, Lt 2, Ruang 201',
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
      isEmergency: false,
      reporterId: 'user1',
      reporterName: 'Ahmad Fauzi',
    ),
    Report(
      id: '2',
      title: 'Kebocoran Pipa Toilet',
      description: 'Air merembes ke lantai',
      category: 'Sanitasi / Air',
      building: 'Gedung C, Lt 1, Toilet Pria',
      status: ReportStatus.terverifikasi, // Was 'verifikasi' in old mock
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isEmergency: false,
      reporterId: 'user2',
      reporterName: 'Siti Aminah',
    ),
    Report(
      id: '3',
      title: 'Kecelakaan di Lab Kimia',
      description: 'Tumpahan bahan kimia berbahaya',
      category: 'K3',
      building: 'Gedung D, Lt 3',
      status: ReportStatus.penanganan,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isEmergency: true,
      reporterId: 'user3',
      reporterName: 'Budi Santoso',
    ),
    Report(
      id: '4',
      title: 'Lampu Koridor Mati',
      description: 'Gelap gulita',
      category: 'Kelistrikan',
      building: 'Gedung A, Lt 1',
      status: ReportStatus.selesai,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isEmergency: false,
      reporterId: 'user4',
      reporterName: 'Dewi Lestari',
    ),
    Report(
      id: '5',
      title: 'Kebakaran Kecil di Kantin',
      description: 'Kompor meledak',
      category: 'K3',
      building: 'Kantin Utama',
      status: ReportStatus.onHold, // Was 'hold'
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      isEmergency: true,
      reporterId: 'user5',
      reporterName: 'Rudi Hartono',
    ),
    Report(
      id: '6',
      title: 'Atap Bocor',
      description: 'Air hujan masuk',
      category: 'Sipil & Bangunan',
      building: 'Gedung B',
      status: ReportStatus.terverifikasi,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isEmergency: false,
      reporterId: 'user6',
      reporterName: 'Budi Santoso',
    ),
  ];

  late String _selectedStatus;
  late bool _showEmergencyOnly;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? 'all';
    _showEmergencyOnly = widget.showEmergencyOnly;
  }

  List<Report> get _filteredReports {
    return _allReports.where((report) {
      // Filter by emergency
      if (_showEmergencyOnly && !report.isEmergency) {
        return false;
      }

      // Filter by status (internal UI chip filter)
      if (_selectedStatus != 'all') {
        // Map string status to enum checking
        if (report.status.name != _selectedStatus) {
          // Basic mapping check, might need smarter check if labels differ
          return false;
        }
      }

      // Filter by period (mock implementation)
      if (widget.initialPeriod != null) {
        final date = report.createdAt;
        final now = DateTime.now();
        if (widget.initialPeriod == 'today') {
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }
      }

      // Filter by specific statuses (from widget params / Tab configuration)
      if (widget.filterStatuses != null) {
        // Check if the report status name is in the allowed list
        // Note: widget.filterStatuses strings must match ReportStatus.name (e.g. 'pending', 'terverifikasi')
        if (!widget.filterStatuses!.contains(report.status.name)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = _showEmergencyOnly
        ? 'Laporan Darurat'
        : widget.initialPeriod != null
        ? 'Laporan ${widget.initialPeriod == 'today'
              ? 'Hari Ini'
              : widget.initialPeriod == 'week'
              ? 'Minggu Ini'
              : 'Bulan Ini'}'
        : 'Daftar Laporan';

    final body = Column(
      children: [
        // Filter Chips (Only show if not in emergency mode AND not in Tab mode, OR if in Tab mode but user wants sub-filters?)
        if (!_showEmergencyOnly)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Semua', 'all'),
                const Gap(8),
                // Only show chips that are relevant
                if (widget.filterStatuses == null ||
                    widget.filterStatuses!.contains('pending')) ...[
                  _buildFilterChip('Pending', 'pending'),
                  const Gap(8),
                ],
                if (widget.filterStatuses == null ||
                    widget.filterStatuses!.contains('terverifikasi')) ...[
                  _buildFilterChip('Terverifikasi', 'terverifikasi'),
                  const Gap(8),
                ],
                if (widget.filterStatuses == null ||
                    widget.filterStatuses!.contains('diproses')) ...[
                  _buildFilterChip('Diproses', 'diproses'),
                  const Gap(8),
                ],
                if (widget.filterStatuses == null ||
                    widget.filterStatuses!.contains('penanganan')) ...[
                  _buildFilterChip('Penanganan', 'penanganan'),
                  const Gap(8),
                ],
                if (widget.filterStatuses == null ||
                    widget.filterStatuses!.contains('selesai')) ...[
                  _buildFilterChip('Selesai', 'selesai'),
                  const Gap(8),
                ],
                if (widget.filterStatuses == null ||
                    widget.filterStatuses!.contains('onHold')) ...[
                  _buildFilterChip('Ditunda', 'onHold'),
                  const Gap(8),
                ],
              ],
            ),
          ),

        Expanded(
          child: _filteredReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.fileX,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const Gap(16),
                      Text(
                        'Tidak ada laporan',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = _filteredReports[index];
                    return ReportCard(
                      report: report,
                      onTap: () =>
                          context.push('/supervisor/review/${report.id}'),
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.isTabMode) {
      return Scaffold(backgroundColor: AppTheme.backgroundColor, body: body);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _showEmergencyOnly ? Colors.red : Colors.white,
        foregroundColor: _showEmergencyOnly ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: body,
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = status);
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
      ),
    );
  }
}
