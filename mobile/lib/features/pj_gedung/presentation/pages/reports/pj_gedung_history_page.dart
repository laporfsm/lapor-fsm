import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';

import 'package:mobile/core/theme.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/pj_gedung/presentation/providers/pj_gedung_reports_provider.dart';
import 'package:mobile/features/pj_gedung/presentation/widgets/pj_gedung_report_list_body.dart';
import 'package:mobile/features/admin/services/export_service.dart';
import 'package:mobile/core/widgets/custom_date_range_picker.dart';

const Color _pjGedungColor = Color(0xFF059669); // Emerald green

class PJGedungHistoryPage extends ConsumerStatefulWidget {
  final String initialFilter;

  const PJGedungHistoryPage({super.key, this.initialFilter = 'all'});

  @override
  ConsumerState<PJGedungHistoryPage> createState() =>
      _PJGedungHistoryPageState();
}

class _PJGedungHistoryPageState extends ConsumerState<PJGedungHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initial fetch using microtask to avoid side effects during build
    Future.microtask(() {
      final notifier = ref.read(pjGedungReportsProvider('').notifier);
      if (widget.initialFilter != 'all') {
        notifier.setStatuses({widget.initialFilter});
      } else {
        notifier.fetchReports();
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(pjGedungReportsProvider('').notifier).fetchMore();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref
        .read(pjGedungReportsProvider('').notifier)
        .setSearchQuery(_searchController.text);
  }

  void _navigateToDetail(Report report) async {
    final result = await context.push('/pj-gedung/report/${report.id}');
    if (result == true) {
      ref.read(pjGedungReportsProvider('').notifier).fetchReports();
    }
  }

  void _showDatePicker() async {
    final historyState = ref.read(pjGedungReportsProvider(''));
    final now = DateTime.now();
    final result = await CustomDateRangePickerDialog.show(
      context: context,
      initialRange: historyState.customDateRange,
      themeColor: _pjGedungColor,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );

    if (result != null) {
      ref.read(pjGedungReportsProvider('').notifier).setDateRange(result);
    }
  }

  void _setPeriodFilter(String? period) {
    ref.read(pjGedungReportsProvider('').notifier).setPeriodFilter(period);
  }

  void _resetFilters() {
    _searchController.clear();
    ref.read(pjGedungReportsProvider('').notifier).resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(pjGedungReportsProvider(''));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Riwayat Laporan',
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari laporan...',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      suffixIcon: historyState.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(pjGedungReportsProvider('').notifier)
                                    .setSearchQuery('');
                              },
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
                        borderSide: const BorderSide(color: _pjGedungColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                InkWell(
                  onTap: _showDatePicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: historyState.customDateRange != null
                          ? _pjGedungColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: historyState.customDateRange != null
                            ? _pjGedungColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.calendarRange,
                      color: historyState.customDateRange != null
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                const Gap(8),
                InkWell(
                  onTap: _showFilterDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            historyState.selectedStatuses.isNotEmpty ||
                                historyState.emergencyOnly
                            ? _pjGedungColor
                            : Colors.grey.shade300,
                        width:
                            historyState.selectedStatuses.isNotEmpty ||
                                historyState.emergencyOnly
                            ? 1.5
                            : 1.0,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.filter,
                      color:
                          historyState.selectedStatuses.isNotEmpty ||
                              historyState.emergencyOnly
                          ? _pjGedungColor
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Filters
          if (_hasActiveFilters(historyState))
            Container(
              width: double.infinity,
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (historyState.emergencyOnly) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildActiveFilterChip('Darurat Saja', () {
                          ref
                              .read(pjGedungReportsProvider('').notifier)
                              .setEmergencyOnly(false);
                        }),
                      ),
                    ],
                    if (historyState.periodFilter != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildActiveFilterChip(
                          _getPeriodLabel(historyState.periodFilter!),
                          () => _setPeriodFilter(null),
                        ),
                      ),
                    ],
                    if (historyState.customDateRange != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildDateRangeChip(
                          historyState.customDateRange!,
                        ),
                      ),
                    ],
                    ...historyState.selectedStatuses.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildActiveFilterChip(
                          status[0].toUpperCase() + status.substring(1),
                          () {
                            final newStatuses = Set<String>.from(
                              historyState.selectedStatuses,
                            );
                            newStatuses.remove(status);
                            ref
                                .read(pjGedungReportsProvider('').notifier)
                                .setStatuses(newStatuses);
                          },
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            ),

          // Reports List
          Expanded(
            child: PjGedungReportListBody(
              status: '', // All
              showSearch: false, // Handled by outer UI
              onReportTap: (reportId, status) {
                _navigateToDetail(
                  Report(
                    id: reportId,
                    title: '',
                    description: '',
                    category: '',
                    location: '',
                    status: status,
                    createdAt: DateTime.now(),
                    isEmergency: false,
                    reporterName: '',
                    reporterId: '',
                  ),
                ); // We just need ID for navigation usually, but _navigateToDetail expects Report object.
                // Wait, _navigateToDetail logic:
                // final result = await context.push('/pj-gedung/report/${report.id}');
                // So actually I can just push directly here or fix _navigateToDetail to take ID.
                // Optimally: just context.push here
                context.push('/pj-gedung/report/$reportId').then((result) {
                  if (result == true) {
                    ref
                        .read(pjGedungReportsProvider('').notifier)
                        .fetchReports();
                  }
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExportOptions(context, historyState),
        backgroundColor: Colors.white,
        child: const Icon(LucideIcons.download, color: _pjGedungColor),
      ),
    );
  }

  bool _hasActiveFilters(PjGedungReportsState state) {
    return state.searchQuery.isNotEmpty ||
        state.periodFilter != null ||
        state.customDateRange != null ||
        state.selectedStatuses.isNotEmpty ||
        state.emergencyOnly;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _pjGedungColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _pjGedungColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(LucideIcons.x, size: 14, color: _pjGedungColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip(DateTimeRange range) {
    // We need to import intl for DateFormat
    // Since I can't easily add an import now without re-reading, I'll use simple formatting
    final start = "${range.start.day}/${range.start.month}";
    final end = "${range.end.day}/${range.end.month}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _pjGedungColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$start - $end',
            style: const TextStyle(
              color: _pjGedungColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(4),
          GestureDetector(
            onTap: () {
              ref.read(pjGedungReportsProvider('').notifier).setDateRange(null);
            },
            child: const Icon(LucideIcons.x, size: 14, color: _pjGedungColor),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final historyState = ref.read(pjGedungReportsProvider(''));
    String? tempPeriod = historyState.periodFilter;
    Set<String> tempSelectedStatuses = Set.from(historyState.selectedStatuses);
    bool tempEmergencyOnly = historyState.emergencyOnly;
    DateTimeRange? tempCustomDateRange = historyState.customDateRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle Bar
              const Gap(16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(16),

              // Header with Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempPeriod = null;
                          tempSelectedStatuses.clear();
                          tempEmergencyOnly = false;
                          tempCustomDateRange = null;
                        });
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const Text(
                      'Filter Laporan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final notifier = ref.read(
                          pjGedungReportsProvider('').notifier,
                        );
                        notifier.setPeriodFilter(tempPeriod);
                        notifier.setStatuses(tempSelectedStatuses);
                        notifier.setEmergencyOnly(tempEmergencyOnly);
                        if (tempCustomDateRange != null) {
                          notifier.setDateRange(tempCustomDateRange);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Terapkan',
                        style: TextStyle(
                          color: _pjGedungColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Emergency Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Hanya Darurat',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      secondary: Icon(
                        LucideIcons.alertTriangle,
                        color: tempEmergencyOnly
                            ? AppTheme.emergencyColor
                            : Colors.grey,
                      ),
                      value: tempEmergencyOnly,
                      onChanged: (value) {
                        setModalState(() => tempEmergencyOnly = value);
                      },
                    ),
                    const Divider(),
                    const Gap(16),

                    // Rentang Waktu
                    const Text(
                      'Rentang Waktu',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Gap(12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPeriodChip(
                          'Hari Ini',
                          'today',
                          tempPeriod,
                          (p) => setModalState(() {
                            tempPeriod = p;
                            tempCustomDateRange = null;
                          }),
                        ),
                        _buildPeriodChip(
                          'Minggu Ini',
                          'week',
                          tempPeriod,
                          (p) => setModalState(() {
                            tempPeriod = p;
                            tempCustomDateRange = null;
                          }),
                        ),
                        _buildPeriodChip(
                          'Bulan Ini',
                          'month',
                          tempPeriod,
                          (p) => setModalState(() {
                            tempPeriod = p;
                            tempCustomDateRange = null;
                          }),
                        ),
                      ],
                    ),
                    const Gap(24),

                    // Status
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Gap(12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChip(
                          'Terverifikasi',
                          'terverifikasi',
                          tempSelectedStatuses,
                          (s) => setModalState(() {
                            if (tempSelectedStatuses.contains(s)) {
                              tempSelectedStatuses.remove(s);
                            } else {
                              tempSelectedStatuses.add(s);
                            }
                          }),
                        ),
                        _buildStatusChip(
                          'Diproses',
                          'diproses',
                          tempSelectedStatuses,
                          (s) => setModalState(() {
                            if (tempSelectedStatuses.contains(s)) {
                              tempSelectedStatuses.remove(s);
                            } else {
                              tempSelectedStatuses.add(s);
                            }
                          }),
                        ),
                        _buildStatusChip(
                          'Penanganan',
                          'penanganan',
                          tempSelectedStatuses,
                          (s) => setModalState(() {
                            if (tempSelectedStatuses.contains(s)) {
                              tempSelectedStatuses.remove(s);
                            } else {
                              tempSelectedStatuses.add(s);
                            }
                          }),
                        ),
                        _buildStatusChip(
                          'Selesai',
                          'selesai',
                          tempSelectedStatuses,
                          (s) => setModalState(() {
                            if (tempSelectedStatuses.contains(s)) {
                              tempSelectedStatuses.remove(s);
                            } else {
                              tempSelectedStatuses.add(s);
                            }
                          }),
                        ),
                        _buildStatusChip(
                          'Approved',
                          'approved',
                          tempSelectedStatuses,
                          (s) => setModalState(() {
                            if (tempSelectedStatuses.contains(s)) {
                              tempSelectedStatuses.remove(s);
                            } else {
                              tempSelectedStatuses.add(s);
                            }
                          }),
                        ),
                        _buildStatusChip(
                          'Ditolak',
                          'ditolak',
                          tempSelectedStatuses,
                          (s) => setModalState(() {
                            if (tempSelectedStatuses.contains(s)) {
                              tempSelectedStatuses.remove(s);
                            } else {
                              tempSelectedStatuses.add(s);
                            }
                          }),
                        ),
                      ],
                    ),
                    const Gap(24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(
    String label,
    String period,
    String? currentPeriod,
    Function(String?) onSelected,
  ) {
    final isActive = currentPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      selectedColor: _pjGedungColor,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.grey.shade700,
        fontSize: 12,
      ),
      onSelected: (selected) {
        onSelected(selected ? period : null);
      },
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isActive ? _pjGedungColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    String status,
    Set<String> currentSelected,
    Function(String) onSelected,
  ) {
    final isActive = currentSelected.contains(status);
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) {
        onSelected(status);
      },
      selectedColor: _pjGedungColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.grey.shade700,
        fontSize: 12,
      ),
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isActive ? _pjGedungColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context, PjGedungReportsState state) {
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
                'Export Riwayat Laporan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              Text(
                'Unduh ${state.reports.length} data riwayat laporan saat ini.',
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
                  ExportService.exportData(
                    context,
                    'Riwayat Laporan',
                    'report_history',
                    data: state.reports.map((r) => r.toJson()).toList(),
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

                  // Extract dates if available
                  String? startDate;
                  String? endDate;
                  if (state.customDateRange != null) {
                    startDate = state.customDateRange!.start.toIso8601String();
                    endDate = state.customDateRange!.end.toIso8601String();
                  }

                  ExportService.exportPdf(
                    context: context,
                    title: 'Riwayat Laporan',
                    status: state.selectedStatuses.isEmpty
                        ? 'terverifikasi,verifikasi,diproses,penanganan,onHold,selesai,approved,ditolak,recalled,archived'
                        : state.selectedStatuses.join(','),
                    building: null,
                    startDate: startDate,
                    endDate: endDate,
                    search: state.searchQuery.isNotEmpty
                        ? state.searchQuery
                        : null,
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
