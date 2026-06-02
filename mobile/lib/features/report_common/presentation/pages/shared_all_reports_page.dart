import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/core/widgets/custom_date_range_picker.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/widgets/report_filter_sheet.dart';

/// A shared page for displaying a list of reports with filters and search.
/// Can be used by both Supervisor and Technician.
class SharedAllReportsPage extends StatefulWidget {
  final List<ReportStatus>? initialStatuses;
  final List<ReportStatus>? allowedStatuses; // New: Restrict filter options
  final String? initialPeriod;
  final bool initialEmergency; // New parameter
  final Function(String reportId, ReportStatus status) onReportTap;
  final String appBarTitle;
  final Color appBarColor;
  final Color appBarIconColor;
  final TextStyle? appBarTitleStyle;
  final bool showBackButton;
  final bool showAppBar;
  final bool enableDateFilter; // New parameter to toggle date filter visibility
  final Widget? floatingActionButton; // New parameter
  final List<Widget>? appBarActions; // New parameter for AppBar action buttons
  final String?
  role; // New parameter to determine if we should fetch staff reports
  final int? assignedTo; // Added parameter for filtering by technician

  const SharedAllReportsPage({
    super.key,
    this.initialStatuses,
    this.allowedStatuses,
    this.initialPeriod,
    this.initialEmergency = false, // Default false
    this.enableDateFilter = true, // Default true
    required this.onReportTap,
    this.appBarTitle = 'Semua Laporan',
    this.appBarColor = Colors.white,
    this.appBarIconColor = Colors.black,
    this.appBarTitleStyle,
    this.showBackButton = true,
    this.showAppBar = true,
    this.floatingActionButton,
    this.appBarActions,
    this.role,
    this.assignedTo,
  });

  @override
  State<SharedAllReportsPage> createState() => _SharedAllReportsPageState();
}

class _SharedAllReportsPageState extends State<SharedAllReportsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Report> _reports = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  int _currentPage = 1;
  int _totalReports = 0;
  bool _hasMore = true;
  final int _limit = 50;
  final ScrollController _scrollController = ScrollController();

  Set<ReportStatus> _selectedStatuses = {};
  Set<String> _selectedCategories = {};
  Set<String> _selectedBuildings = {};
  bool _emergencyOnly = false;

  String? _selectedPeriod; // 'today', 'week', 'month'
  DateTimeRange? _selectedDateRange; // Custom date range

  List<String> _categoryNames = [];

  bool _isSelectionMode = false;
  final Set<String> _selectedReportIds = {};

  void _toggleSelectionMode(String reportId) {
    if (widget.role != 'supervisor') return;

    // Validation: Only allow if initial report is valid
    final report = _reports.firstWhere((r) => r.id == reportId);
    if (!_isReportMergeable(report)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Laporan ini tidak dapat digabungkan (Status harus Menunggu Verifikasi/Terverifikasi)',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSelectionMode = true;
      _selectedReportIds.add(reportId);
    });
  }

  void _toggleSelection(String reportId) {
    final report = _reports.firstWhere((r) => r.id == reportId);

    if (_selectedReportIds.contains(reportId)) {
      setState(() {
        _selectedReportIds.remove(reportId);
        if (_selectedReportIds.isEmpty) {
          _isSelectionMode = false;
        }
      });
      return;
    }

    // Validation: Check Status
    if (!_isReportMergeable(report)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status laporan tidak valid untuk digabungkan'),
        ),
      );
      return;
    }

    // Validation: Check Building match
    if (_selectedReportIds.isNotEmpty) {
      final firstId = _selectedReportIds.first;
      final firstReport = _reports.firstWhere((r) => r.id == firstId);
      if (report.location != firstReport.location) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi harus sama dengan laporan pertama (${firstReport.location})',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _selectedReportIds.add(reportId);
    });
  }

  bool _isReportMergeable(Report report) {
    // Only allow merging if status is Pending or Verified (Not assigned yet)
    return report.status == ReportStatus.pending ||
        report.status == ReportStatus.terverifikasi ||
        report.status == ReportStatus.verifikasi;
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedReportIds.clear();
    });
  }

  Future<void> _groupSelectedReports() async {
    if (_selectedReportIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 2 laporan untuk digabungkan'),
        ),
      );
      return;
    }

    final notesController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gabungkan Laporan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan menggabungkan ${_selectedReportIds.length} laporan menjadi satu group.',
              style: const TextStyle(fontSize: 14),
            ),
            const Gap(16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Penggabungan',
                hintText: 'Opsional',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              const Gap(8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.supervisorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('Gabungkan'),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final authService = AuthService();
        final user = await authService.getCurrentUser();

        if (user == null || user['id'] == null) {
          throw Exception('Gagal mendapatkan identitas pengguna');
        }

        final staffId = int.tryParse(user['id'].toString()) ?? 0;
        if (staffId == 0) {
          throw Exception('ID Pengguna tidak valid');
        }

        await reportService.groupReports(
          _selectedReportIds.toList(),
          staffId,
          notes: notesController.text,
        );
        if (!mounted || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil digabungkan')),
        );
        _exitSelectionMode();
        _fetchReports();
      } catch (e) {
        if (!mounted || !context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initFilters();
    _scrollController.addListener(_onScroll);
    _fetchData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isFetchingMore &&
        _hasMore &&
        !_isLoading) {
      _fetchMoreReports();
    }
  }

  void _initFilters() {
    if (widget.initialStatuses != null && widget.initialStatuses!.isNotEmpty) {
      _selectedStatuses = widget.initialStatuses!.toSet();
    }

    if (widget.initialPeriod != null) {
      _selectedPeriod = widget.initialPeriod;
    }

    _emergencyOnly = widget.initialEmergency; // Initialize emergency filter
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchReports(), _fetchCategories(), _fetchBuildings()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchBuildings() async {
    try {
      final buildings = await reportService.getLocations();
      if (mounted) {
        setState(() {
          _buildings = buildings.map((b) => b['name'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching buildings: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await reportService.getCategories();
      if (mounted) {
        setState(() {
          _categoryNames = categories.map((c) => c['name'] as String).toList()
            ..sort();
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _fetchReports({bool isRefresh = true}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      Map<String, dynamic> response;

      if (widget.role != null) {
        // Fetch Staff-specific reports
        response = await reportService.getStaffReports(
          role: widget.role!,
          status: _selectedStatuses.isNotEmpty
              ? _selectedStatuses.map((s) => s.name).join(',')
              : widget.allowedStatuses?.map((s) => s.name).join(','),
          isEmergency: _emergencyOnly ? true : null,
          period: _selectedPeriod,
          category: _selectedCategories.isNotEmpty
              ? _selectedCategories.join(',')
              : null,
          location: _selectedBuildings.isNotEmpty
              ? _selectedBuildings.join(',')
              : null,
          assignedTo: widget.assignedTo,
          page: _currentPage,
          limit: _limit,
        );
      } else {
        // Fetch Public reports
        response = await reportService.getPublicReports(
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          status: _selectedStatuses.isNotEmpty
              ? _selectedStatuses.map((s) => s.name).join(',')
              : widget.allowedStatuses?.map((s) => s.name).join(','),
          category: _selectedCategories.isNotEmpty
              ? _selectedCategories.join(',')
              : null,
          location: _selectedBuildings.isNotEmpty
              ? _selectedBuildings.join(',')
              : null,
          isEmergency: _emergencyOnly,
          period: _selectedPeriod,
          startDate: _selectedDateRange?.start.toIso8601String(),
          endDate: _selectedDateRange?.end.toIso8601String(),
          limit: _limit,
          offset: (_currentPage - 1) * _limit,
        );
      }

      final List<Map<String, dynamic>> reportsData =
          List<Map<String, dynamic>>.from(response['data'] ?? []);
      final int total = response['total'] ?? 0;

      if (mounted) {
        setState(() {
          final newReports = reportsData
              .map((json) {
                try {
                  return Report.fromJson(json);
                } catch (e) {
                  debugPrint('Error parsing report item: $e');
                  return null;
                }
              })
              .whereType<Report>()
              .toList();
          if (isRefresh) {
            _reports = newReports;
          } else {
            _reports.addAll(newReports);
          }
          _totalReports = total;
          _hasMore = _reports.length < _totalReports;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    }
  }

  Future<void> _fetchMoreReports() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;
    await _fetchReports(isRefresh: false);
    if (mounted) setState(() => _isFetchingMore = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  List<String> _buildings = [];

  bool get _hasActiveFilters {
    bool hasDateFilter = false;
    if (widget.enableDateFilter) {
      hasDateFilter = _selectedPeriod != null || _selectedDateRange != null;
    }
    return _selectedStatuses.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _selectedBuildings.isNotEmpty ||
        hasDateFilter ||
        _emergencyOnly;
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

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari laporan...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: BouncingButton(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _fetchReports();
                              },
                              child: const Icon(LucideIcons.x, size: 18),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.appBarColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _fetchReports();
                  },
                ),
              ),
              if (widget.enableDateFilter) ...[
                const Gap(12),
                BouncingButton(
                  onTap: _showCustomDateRangePicker,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedDateRange != null
                          ? widget.appBarColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedDateRange != null
                            ? widget.appBarColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.calendarRange,
                      color: _selectedDateRange != null
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
              const Gap(8),
              BouncingButton(
                onTap: _showFilterSheet,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasActiveFilters
                          ? (widget.appBarColor == Colors.white
                                ? AppTheme.primaryColor
                                : widget.appBarColor)
                          : Colors.grey.shade300,
                      width: _hasActiveFilters ? 1.5 : 1.0,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.filter,
                    color: _hasActiveFilters
                        ? (widget.appBarColor == Colors.white
                              ? AppTheme.primaryColor
                              : widget.appBarColor)
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Active Filters
        if (_hasActiveFilters)
          Container(
            width: double.infinity,
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._selectedStatuses.map(
                    (s) => _buildFilterChip(s.label, s.color, LucideIcons.info, () {
                      setState(() => _selectedStatuses.remove(s));
                      _fetchReports();
                    }),
                  ),
                  ..._selectedCategories.map(
                    (cat) => _buildFilterChip(cat, Colors.purple, LucideIcons.tag, () {
                      setState(() => _selectedCategories.remove(cat));
                      _fetchReports();
                    }),
                  ),
                  ..._selectedBuildings.map(
                    (building) => _buildFilterChip(building, Colors.teal, LucideIcons.mapPin, () {
                      setState(() => _selectedBuildings.remove(building));
                      _fetchReports();
                    }),
                  ),
                  if (_emergencyOnly)
                    _buildFilterChip(
                      'Darurat',
                      AppTheme.emergencyColor,
                      LucideIcons.alertTriangle,
                      () {
                        setState(() => _emergencyOnly = false);
                        _fetchReports();
                      },
                    ),
                  if (_selectedPeriod != null)
                    _buildFilterChip(
                      _getPeriodLabel(_selectedPeriod!),
                      Colors.blue,
                      LucideIcons.calendar,
                      () {
                        setState(() => _selectedPeriod = null);
                        _fetchReports();
                      },
                    ),
                  if (_selectedDateRange != null)
                    _buildFilterChip(
                      '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                      widget.appBarColor == Colors.white || widget.appBarColor == Colors.transparent
                          ? AppTheme.primaryColor
                          : widget.appBarColor,
                      LucideIcons.calendarRange,
                      () {
                        setState(() => _selectedDateRange = null);
                        _fetchReports();
                      },
                    ),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ),

        // Results Count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            '$_totalReports laporan ditemukan',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),

        // Reports List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchReports,
                  child: _reports.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.searchX,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const Gap(16),
                              Text(
                                'Tidak ada laporan ditemukan',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _reports.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _reports.length) {
                              if (_hasMore) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else if (_reports.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          LucideIcons.checkCircle2,
                                          size: 20,
                                          color: Colors.grey.shade400,
                                        ),
                                        const Gap(8),
                                        Text(
                                          'Semua laporan telah dimuat',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            }
                            final report = _reports[index];
                            return UniversalReportCard(
                              id: report.id,
                              title: report.title,
                              location: report.location,
                              locationDetail: report.locationDetail,
                              category: report.category,
                              status: report.status,
                              isEmergency: report.isEmergency,
                              reporterName: report.reporterName,
                              assignedTo: report.assignedTo,
                              handledBy: report.handledBy,
                              elapsedTime: report.elapsed,
                              createdAt: report.createdAt,
                              pausedAt: report.pausedAt,
                              totalPausedDurationSeconds:
                                  report.totalPausedDurationSeconds,
                              showStatus: true,
                              showTimer: true,
                              selectionMode: _isSelectionMode,
                              isSelected: _selectedReportIds.contains(
                                report.id,
                              ),
                              isParent: report.isParent,
                              mergedCount: report.mergedCount,
                              onLongPress: () =>
                                  _toggleSelectionMode(report.id),
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(report.id);
                                } else {
                                  widget.onReportTap(report.id, report.status);
                                }
                              },
                            );
                          },
                        ),
                ),
        ),
        if (_isSelectionMode)
          Container(
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
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedReportIds.length} terpilih',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Ketuk untuk memilih',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _exitSelectionMode,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const Gap(8),
                    ElevatedButton.icon(
                      onPressed: _selectedReportIds.length >= 2
                          ? _groupSelectedReports
                          : null,
                      icon: const Icon(LucideIcons.combine, size: 18),
                      label: const Text(
                        'Gabungkan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.appBarColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _isSelectionMode
            ? AppBar(
                title: Text('${_selectedReportIds.length} Laporan Terpilih'),
                backgroundColor: AppTheme.supervisorColor,
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  onPressed: _exitSelectionMode,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.combine, color: Colors.white),
                    onPressed: _groupSelectedReports,
                    tooltip: 'Gabungkan Laporan',
                  ),
                ],
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : AppBar(
                title: Text(widget.appBarTitle),
                backgroundColor: widget.appBarColor,
                centerTitle: true,
                titleTextStyle:
                    widget.appBarTitleStyle ??
                    TextStyle(
                      color: widget.appBarIconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                leading: widget.showBackButton
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.arrowLeft,
                          color: widget.appBarIconColor,
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                actions: widget.appBarActions,
              ),
        body: content,
        floatingActionButton: _isSelectionMode
            ? FloatingActionButton.extended(
                onPressed: _groupSelectedReports,
                backgroundColor: AppTheme.supervisorColor,
                label: const Text('Gabungkan'),
                icon: const Icon(LucideIcons.combine),
              )
            : widget.floatingActionButton,
      );
    } else {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: content, // No AppBar
        floatingActionButton: _isSelectionMode
            ? null
            : widget.floatingActionButton,
      );
    }
  }

  Widget _buildFilterChip(
    String label,
    Color color,
    IconData icon,
    VoidCallback onRemove,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const Gap(6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.x, size: 12, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatuses.clear();
      _selectedCategories.clear();
      _selectedBuildings.clear();
      _emergencyOnly = false;
      _selectedPeriod = null;
      _selectedDateRange = null;
    });
    _fetchReports();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReportFilterSheet(
        selectedStatuses: _selectedStatuses,
        selectedCategories: _selectedCategories,
        selectedBuildings: _selectedBuildings,
        isEmergency: _emergencyOnly,
        selectedPeriod: _selectedPeriod,
        selectedDateRange: _selectedDateRange,
        availableCategories: _categoryNames,
        availableBuildings: _buildings,
        themeColor: widget.appBarColor == Colors.white
            ? AppTheme.primaryColor
            : widget.appBarColor,
        allowedStatuses: widget.allowedStatuses,
        onReset: _clearAllFilters,
        onChanged: ({
          buildings,
          categories,
          dateRange,
          isEmergency,
          period,
          statuses,
        }) {
          setState(() {
            if (statuses != null) _selectedStatuses = statuses;
            if (categories != null) _selectedCategories = categories;
            if (buildings != null) _selectedBuildings = buildings;
            if (isEmergency != null) _emergencyOnly = isEmergency;
            if (period != null) {
              _selectedPeriod = period;
              _selectedDateRange = null;
            }
            if (dateRange != null) {
              _selectedDateRange = dateRange;
              _selectedPeriod = null;
            }
          });
          _fetchReports();
        },
      ),
    );
  }

  Future<void> _showCustomDateRangePicker() async {
    final newDateRange = await CustomDateRangePickerDialog.show(
      context: context,
      initialRange: _selectedDateRange,
      themeColor: widget.appBarColor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
        _selectedPeriod = null;
      });
      _fetchReports();
    }
  }
}
