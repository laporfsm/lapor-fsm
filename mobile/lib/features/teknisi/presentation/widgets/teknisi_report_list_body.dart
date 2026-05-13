import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/teknisi/presentation/providers/teknisi_reports_provider.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/core/widgets/report_filter_sheet.dart';
import 'package:mobile/core/widgets/custom_date_range_picker.dart';

class TeknisiReportListBody extends ConsumerStatefulWidget {
  final String status;
  final Function(String reportId, ReportStatus status) onReportTap;
  final Color? themeColor;
  final bool showSearch;
  final int? assignedTo;

  const TeknisiReportListBody({
    super.key,
    required this.status,
    required this.onReportTap,
    this.themeColor,
    this.showSearch = true,
    this.assignedTo,
  });

  @override
  ConsumerState<TeknisiReportListBody> createState() =>
      _TeknisiReportListBodyState();
}

class _TeknisiReportListBodyState extends ConsumerState<TeknisiReportListBody> {
  final ScrollController _scrollController = ScrollController();
  List<String> _categories = [];
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teknisiReportsProvider(widget.status).notifier).setFilters(
            assignedTo: widget.assignedTo,
          );
      _fetchFilterData();
    });
  }

  Future<void> _fetchFilterData() async {
    try {
      final cats = await reportService.getCategories();
      final locs = await reportService.getLocations();
      if (mounted) {
        setState(() {
          _categories = cats.map((c) => c['name'] as String).toList()..sort();
          _locations = locs.map((l) => l['name'] as String).toList()..sort();
        });
      }
    } catch (e) {
      debugPrint('Error fetching filter data: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(teknisiReportsProvider(widget.status).notifier).loadReports();
    }
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
                  child: Icon(LucideIcons.x, size: 10, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final notifier = ref.read(teknisiReportsProvider(widget.status).notifier);
    final currentState = ref.watch(teknisiReportsProvider(widget.status));
    final themeColor = widget.themeColor ?? AppTheme.secondaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReportFilterSheet(
        selectedStatuses: currentState.selectedStatus != null
            ? ReportStatus.values
                .where((s) => currentState.selectedStatus!.split(',').contains(s.name))
                .toSet()
            : {},
        selectedCategories: currentState.categories.toSet(),
        selectedBuildings: currentState.locations.toSet(),
        isEmergency: currentState.isEmergency ?? false,
        selectedPeriod: currentState.period,
        selectedDateRange: (currentState.startDate != null && currentState.endDate != null)
            ? DateTimeRange(start: currentState.startDate!, end: currentState.endDate!)
            : null,
        availableCategories: _categories,
        availableBuildings: _locations,
        themeColor: themeColor,
        onReset: () => notifier.clearFilters(),
        onChanged: ({
          buildings,
          categories,
          dateRange,
          isEmergency,
          period,
          statuses,
        }) {
          notifier.setFilters(
            categories: categories?.toList(),
            locations: buildings?.toList(),
            isEmergency: isEmergency,
            period: period,
            startDate: dateRange?.start,
            endDate: dateRange?.end,
            selectedStatus: statuses?.isEmpty ?? true
                ? null
                : statuses!.map((s) => s.name).join(','),
          );
        },
      ),
    );
  }

  Future<void> _showCustomDateRangePicker() async {
    final state = ref.read(teknisiReportsProvider(widget.status));
    final notifier = ref.read(teknisiReportsProvider(widget.status).notifier);
    final themeColor = widget.themeColor ?? AppTheme.secondaryColor;

    final initialRange = (state.startDate != null && state.endDate != null)
        ? DateTimeRange(start: state.startDate!, end: state.endDate!)
        : null;

    final newDateRange = await CustomDateRangePickerDialog.show(
      context: context,
      initialRange: initialRange,
      themeColor: themeColor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (newDateRange != null) {
      notifier.setFilters(
        categories: state.categories,
        locations: state.locations,
        isEmergency: state.isEmergency,
        period: null,
        startDate: newDateRange.start,
        endDate: newDateRange.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teknisiReportsProvider(widget.status));
    final notifier = ref.read(teknisiReportsProvider(widget.status).notifier);
    final themeColor = widget.themeColor ?? AppTheme.secondaryColor;

    final hasActiveFilters = state.categories.isNotEmpty ||
        state.locations.isNotEmpty ||
        (state.isEmergency ?? false) ||
        state.period != null ||
        state.startDate != null ||
        (state.selectedStatus != null);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(teknisiReportsProvider(widget.status).notifier).refresh(),
      child: Column(
        children: [
          if (widget.showSearch)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => notifier.setSearch(value),
                      decoration: InputDecoration(
                        hintText: 'Cari laporan...',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
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
                          borderSide: BorderSide(color: themeColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  BouncingButton(
                    onTap: _showCustomDateRangePicker,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: state.startDate != null
                            ? themeColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.startDate != null
                              ? themeColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.calendarRange,
                        color: state.startDate != null
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const Gap(8),
                  BouncingButton(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasActiveFilters
                              ? themeColor
                              : Colors.grey.shade300,
                          width: hasActiveFilters ? 1.5 : 1.0,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.filter,
                        color: hasActiveFilters
                            ? themeColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (hasActiveFilters)
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
                    if (state.selectedStatus != null &&
                        state.selectedStatus != widget.status)
                      ...state.selectedStatus!.split(',').map((statusName) {
                        final status = ReportStatus.values.firstWhere(
                          (s) => s.name == statusName,
                          orElse: () => ReportStatus.pending,
                        );
                        return _buildFilterChip(
                          status.label,
                          status.color,
                          LucideIcons.info,
                          () {
                            final currentStatuses =
                                state.selectedStatus!.split(',');
                            currentStatuses.remove(statusName);
                            notifier.setFilters(
                              selectedStatus: currentStatuses.isEmpty
                                  ? null
                                  : currentStatuses.join(','),
                            );
                          },
                        );
                      }),
                    ...state.categories.map(
                      (cat) => _buildFilterChip(
                        cat,
                        Colors.purple,
                        LucideIcons.tag,
                        () {
                          final newCats = List<String>.from(state.categories)..remove(cat);
                          notifier.setFilters(
                            categories: newCats,
                            locations: state.locations,
                            isEmergency: state.isEmergency,
                            period: state.period,
                            startDate: state.startDate,
                            endDate: state.endDate,
                            assignedTo: state.assignedTo,
                          );
                        },
                      ),
                    ),
                    ...state.locations.map(
                      (loc) => _buildFilterChip(
                        loc,
                        Colors.teal,
                        LucideIcons.mapPin,
                        () {
                          final newLocs = List<String>.from(state.locations)..remove(loc);
                          notifier.setFilters(
                            categories: state.categories,
                            locations: newLocs,
                            isEmergency: state.isEmergency,
                            period: state.period,
                            startDate: state.startDate,
                            endDate: state.endDate,
                            assignedTo: state.assignedTo,
                          );
                        },
                      ),
                    ),
                    if (state.isEmergency ?? false)
                      _buildFilterChip(
                        'Darurat',
                        AppTheme.emergencyColor,
                        LucideIcons.alertTriangle,
                        () {
                          notifier.setFilters(
                            categories: state.categories,
                            locations: state.locations,
                            isEmergency: false,
                            period: state.period,
                            startDate: state.startDate,
                            endDate: state.endDate,
                            assignedTo: state.assignedTo,
                          );
                        },
                      ),
                    if (state.period != null)
                      _buildFilterChip(
                        _getPeriodLabel(state.period!),
                        Colors.blue,
                        LucideIcons.calendar,
                        () {
                          notifier.setFilters(
                            categories: state.categories,
                            locations: state.locations,
                            isEmergency: state.isEmergency,
                            period: null,
                            startDate: state.startDate,
                            endDate: state.endDate,
                            assignedTo: state.assignedTo,
                          );
                        },
                      ),
                    if (state.startDate != null && state.endDate != null)
                      _buildFilterChip(
                        '${DateFormat('dd MMM').format(state.startDate!)} - ${DateFormat('dd MMM').format(state.endDate!)}',
                        themeColor,
                        LucideIcons.calendarRange,
                        () {
                          notifier.setFilters(
                            categories: state.categories,
                            locations: state.locations,
                            isEmergency: state.isEmergency,
                            period: state.period,
                            startDate: null,
                            endDate: null,
                            assignedTo: state.assignedTo,
                          );
                        },
                      ),
                    TextButton(
                      onPressed: () => notifier.clearFilters(),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: (state.isLoading && state.reports.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : (state.error != null && state.reports.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.error!),
                        const Gap(16),
                        ElevatedButton(
                          onPressed: () => notifier.refresh(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : state.reports.isEmpty
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
                        const Text(
                          'Tidak ada laporan',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.reports.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.reports.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final report = state.reports[index];
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
                        onTap: () =>
                            widget.onReportTap(report.id, report.status),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
