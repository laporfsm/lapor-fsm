import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/presentation/widgets/report_card.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_report_detail_page.dart';
import 'package:mobile/core/widgets/custom_date_range_picker.dart';
import 'package:intl/intl.dart';

const Color _pjGedungColor = Color(0xFF059669); // Emerald green

class PJGedungHistoryPage extends StatefulWidget {
  final String initialFilter;

  const PJGedungHistoryPage({super.key, this.initialFilter = 'all'});

  @override
  State<PJGedungHistoryPage> createState() => _PJGedungHistoryPageState();
}

class _PJGedungHistoryPageState extends State<PJGedungHistoryPage> {
  late String _activeFilter;
  bool _isLoading = true;
  List<Report> _allReports = [];
  List<Report> _filteredReports = [];

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _periodFilter; // 'today', 'week', 'month', or null
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    _fetchReports();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    // MOCK DATA
    _allReports = [
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
      Report(
        id: 'mock-pj-v1',
        title: 'Proyektor Buram',
        description: 'Lensa kotor atau rusak.',
        category: 'Fasilitas Kelas',
        building: 'Gedung A, R. 204',
        status: ReportStatus.terverifikasi,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
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
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        reporterId: 'r5',
        reporterName: 'Satpam',
        isEmergency: false,
      ),
    ];

    if (mounted) {
      setState(() {
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    List<Report> result = List.from(_allReports);

    // Filter by status
    if (_activeFilter == 'pending') {
      result = result.where((r) => r.status == ReportStatus.pending).toList();
    } else if (_activeFilter == 'verified') {
      result = result
          .where((r) => r.status == ReportStatus.terverifikasi)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where(
            (r) =>
                r.title.toLowerCase().contains(query) ||
                r.building.toLowerCase().contains(query) ||
                r.category.toLowerCase().contains(query),
          )
          .toList();
    }

    // Filter by period
    if (_periodFilter != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      result = result.where((r) {
        switch (_periodFilter) {
          case 'today':
            return r.createdAt.isAfter(today);
          case 'week':
            return r.createdAt.isAfter(today.subtract(const Duration(days: 7)));
          case 'month':
            return r.createdAt.isAfter(
              DateTime(now.year, now.month - 1, now.day),
            );
          default:
            return true;
        }
      }).toList();
    }

    // Filter by custom date range
    if (_customDateRange != null) {
      result = result
          .where(
            (r) =>
                r.createdAt.isAfter(_customDateRange!.start) &&
                r.createdAt.isBefore(
                  _customDateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
    }

    _filteredReports = result;
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _periodFilter = null;
      _customDateRange = null;
      _applyFilters();
    });
  }

  void _showDatePicker() async {
    final now = DateTime.now();
    final result = await CustomDateRangePickerDialog.show(
      context: context,
      initialRange: _customDateRange,
      themeColor: _pjGedungColor,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );

    if (result != null) {
      setState(() {
        _customDateRange = result;
        _periodFilter = null; // Clear period filter
        _applyFilters();
      });
    }
  }

  void _setPeriodFilter(String? period) {
    setState(() {
      _periodFilter = period;
      _customDateRange = null; // Clear custom date range
      _applyFilters();
    });
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
        title: const Text(
          'Riwayat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _pjGedungColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar & Date Picker
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari laporan...',
                          prefixIcon: const Icon(LucideIcons.search, size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.calendar,
                          color: _customDateRange != null
                              ? _pjGedungColor
                              : Colors.grey.shade600,
                        ),
                        onPressed: _showDatePicker,
                      ),
                    ),
                    const Gap(8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.filter,
                          color: _activeFilter != 'all'
                              ? _pjGedungColor
                              : Colors.grey.shade600,
                        ),
                        onPressed: _showFilterDialog,
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                // Active Filters Only
                if (_hasActiveFilters())
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_periodFilter != null) ...[
                          _buildActiveFilterChip(
                            _getPeriodLabel(_periodFilter!),
                            () => _setPeriodFilter(null),
                          ),
                          const Gap(8),
                        ],
                        if (_customDateRange != null) ...[
                          _buildDateRangeChip(),
                          const Gap(8),
                        ],
                        if (_activeFilter != 'all') ...[
                          _buildActiveFilterChip(
                            _activeFilter == 'pending'
                                ? 'Perlu Verifikasi'
                                : 'Terverifikasi',
                            () {
                              setState(() {
                                _activeFilter = 'all';
                                _applyFilters();
                              });
                            },
                          ),
                          const Gap(8),
                        ],
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.inbox,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const Gap(16),
                        Text(
                          'Tidak ada laporan ditemukan',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReports.length,
                    separatorBuilder: (c, i) => const Gap(16),
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      return ReportCard(
                        report: report,
                        viewerRole: UserRole.pjGedung,
                        actionLabel: report.status == ReportStatus.pending
                            ? "Verifikasi"
                            : "Lihat",
                        onAction: () => _navigateToDetail(report),
                        onTap: () => _navigateToDetail(report),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExportOptions(context),
        backgroundColor: Colors.white,
        child: const Icon(LucideIcons.download, color: _pjGedungColor),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _periodFilter != null ||
        _customDateRange != null ||
        _activeFilter != 'all';
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'today':
        return 'Hari Ini';
      case 'week':
        return 'Minggu Ini';
      case 'month':
        return 'Bulan Ini';
      default:
        return period;
    }
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(LucideIcons.x, size: 16),
      onDeleted: onRemove,
      backgroundColor: _pjGedungColor.withOpacity(0.2),
      labelStyle: const TextStyle(
        color: _pjGedungColor,
        fontWeight: FontWeight.w500,
      ),
      deleteIconColor: _pjGedungColor,
    );
  }

  Widget _buildDateRangeChip() {
    final dateFormat = DateFormat('dd MMM');
    final start = dateFormat.format(_customDateRange!.start);
    final end = dateFormat.format(_customDateRange!.end);

    return Chip(
      label: Text('$start - $end'),
      deleteIcon: const Icon(LucideIcons.x, size: 16),
      onDeleted: () {
        setState(() {
          _customDateRange = null;
          _applyFilters();
        });
      },
      backgroundColor: _pjGedungColor.withOpacity(0.2),
      labelStyle: const TextStyle(color: _pjGedungColor),
      deleteIconColor: _pjGedungColor,
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Gap(16),

                // Rentang Waktu
                const Text(
                  'Rentang Waktu',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPeriodChip('Hari Ini', 'today', setModalState),
                    _buildPeriodChip('Minggu Ini', 'week', setModalState),
                    _buildPeriodChip('Bulan Ini', 'month', setModalState),
                  ],
                ),
                const Gap(20),

                // Status
                const Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip('Semua', 'all', setModalState),
                    _buildStatusChip(
                      'Perlu Verifikasi',
                      'pending',
                      setModalState,
                    ),
                    _buildStatusChip(
                      'Terverifikasi',
                      'verified',
                      setModalState,
                    ),
                  ],
                ),
                const Gap(16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(
    String label,
    String period,
    StateSetter setModalState,
  ) {
    final isActive = _periodFilter == period;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.calendar,
            size: 16,
            color: isActive ? Colors.white : Colors.grey.shade600,
          ),
          const Gap(6),
          Text(label),
        ],
      ),
      selected: isActive,
      selectedColor: _pjGedungColor,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.grey.shade700,
      ),
      onSelected: (selected) {
        setModalState(() {});
        setState(() {
          _periodFilter = selected ? period : null;
          _customDateRange = null;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildStatusChip(
    String label,
    String status,
    StateSetter setModalState,
  ) {
    final isActive = _activeFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      selectedColor: _pjGedungColor,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.grey.shade700,
      ),
      onSelected: (selected) {
        if (selected) {
          setModalState(() {});
          setState(() {
            _activeFilter = status;
            _applyFilters();
          });
        }
      },
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
