import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/supervisor/presentation/providers/supervisor_reports_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/core/widgets/custom_date_range_picker.dart';
import 'package:mobile/core/widgets/report_filter_sheet.dart';

class SupervisorReportListBody extends ConsumerStatefulWidget {
  final String status;
  final Function(String reportId, ReportStatus status) onReportTap;
  final bool showSearch;
  final String? category;
  final String? location;
  final bool? isEmergency;
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;
  final Widget? floatingActionButton;
  final List<Map<String, String>>? statusFilterOptions;

  const SupervisorReportListBody({
    super.key,
    required this.status,
    required this.onReportTap,
    this.showSearch = false,
    this.category,
    this.location,
    this.isEmergency,
    this.period,
    this.startDate,
    this.endDate,
    this.floatingActionButton,
    this.statusFilterOptions,
  });

  @override
  ConsumerState<SupervisorReportListBody> createState() =>
      _SupervisorReportListBodyState();
}

class _SupervisorReportListBodyState
    extends ConsumerState<SupervisorReportListBody> {
  final ScrollController _scrollController = ScrollController();
  List<String> _categories = [];
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(supervisorReportsProvider(widget.status).notifier)
          .setFilters(
            categories: widget.category != null ? [widget.category!] : null,
            locations: widget.location != null ? [widget.location!] : null,
            isEmergency: widget.isEmergency,
            period: widget.period,
            startDate: widget.startDate,
            endDate: widget.endDate,
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
  void didUpdateWidget(covariant SupervisorReportListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.category != oldWidget.category ||
        widget.location != oldWidget.location ||
        widget.isEmergency != oldWidget.isEmergency ||
        widget.period != oldWidget.period ||
        widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(supervisorReportsProvider(widget.status).notifier)
            .setFilters(
              categories: widget.category != null ? [widget.category!] : null,
              locations: widget.location != null ? [widget.location!] : null,
              isEmergency: widget.isEmergency,
              period: widget.period,
              startDate: widget.startDate,
              endDate: widget.endDate,
            );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = ref.read(
        supervisorReportsProvider(widget.status).notifier,
      );
      final state = ref.read(supervisorReportsProvider(widget.status));
      if (!state.isLoadingMore && state.hasMore) {
        provider.loadReports();
      }
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
    final notifier = ref.read(supervisorReportsProvider(widget.status).notifier);
    final currentState = ref.watch(supervisorReportsProvider(widget.status));

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
        themeColor: AppTheme.supervisorColor,
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
    final state = ref.read(supervisorReportsProvider(widget.status));
    final notifier = ref.read(
      supervisorReportsProvider(widget.status).notifier,
    );

    final initialRange = (state.startDate != null && state.endDate != null)
        ? DateTimeRange(start: state.startDate!, end: state.endDate!)
        : null;

    final newDateRange = await CustomDateRangePickerDialog.show(
      context: context,
      initialRange: initialRange,
      themeColor: AppTheme.supervisorColor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (newDateRange != null) {
      notifier.setFilters(
        categories: state.categories,
        locations: state.locations,
        isEmergency: state.isEmergency,
        period: null, // Clear period when using custom date range
        startDate: newDateRange.start,
        endDate: newDateRange.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supervisorReportsProvider(widget.status));
    final notifier = ref.read(
      supervisorReportsProvider(widget.status).notifier,
    );

    final hasActiveFilters = state.categories.isNotEmpty ||
        state.locations.isNotEmpty ||
        (state.isEmergency ?? false) ||
        state.period != null ||
        state.startDate != null ||
        (state.selectedStatus != null && state.selectedStatus != widget.status);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          _onScroll();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Column(
          children: [
            if (widget.showSearch || (widget.statusFilterOptions != null && widget.statusFilterOptions!.isNotEmpty))
              Container(
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showSearch)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                                    borderSide: const BorderSide(
                                      color: AppTheme.supervisorColor,
                                    ),
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
                                      ? AppTheme.supervisorColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: state.startDate != null
                                        ? AppTheme.supervisorColor
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
                                        ? AppTheme.supervisorColor
                                        : Colors.grey.shade300,
                                    width: hasActiveFilters ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Icon(
                                  LucideIcons.filter,
                                  color: hasActiveFilters
                                      ? AppTheme.supervisorColor
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (widget.statusFilterOptions != null && widget.statusFilterOptions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: widget.statusFilterOptions!.map((option) {
                              final optionValue = option['value'];
                              final isSelected = state.selectedStatus == optionValue;
                              
                              // Determine color based on status value
                              // If value contains multiple statuses (like "Semua"), use supervisor color
                              Color chipColor = AppTheme.supervisorColor;
                              if (optionValue != null && !optionValue.contains(',')) {
                                chipColor = AppTheme.getStatusColor(optionValue);
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(option['label']!),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    notifier.setSelectedStatus(selected ? optionValue : null);
                                  },
                                  backgroundColor: Colors.grey.shade100,
                                  selectedColor: chipColor.withValues(alpha: 0.2),
                                  labelStyle: TextStyle(
                                    color: isSelected ? chipColor : Colors.grey.shade700,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected ? chipColor : Colors.grey.shade300,
                                    ),
                                  ),
                                  showCheckmark: false,
                                ),
                              );
                            }).toList(),
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
                      if (state.selectedStatus != null && state.selectedStatus!.isNotEmpty)
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
                              final currentStatuses = state.selectedStatus!.split(',');
                              currentStatuses.remove(statusName);
                              notifier.setSelectedStatus(
                                currentStatuses.isEmpty ? null : currentStatuses.join(','),
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
                            );
                          },
                        ),
                      if (state.startDate != null && state.endDate != null)
                        _buildFilterChip(
                          '${DateFormat('dd MMM').format(state.startDate!)} - ${DateFormat('dd MMM').format(state.endDate!)}',
                          AppTheme.supervisorColor,
                          LucideIcons.calendarRange,
                          () {
                            notifier.setFilters(
                              categories: state.categories,
                              locations: state.locations,
                              isEmergency: state.isEmergency,
                              period: state.period,
                              startDate: null,
                              endDate: null,
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
              child: RefreshIndicator(
                onRefresh: () async {
                  await notifier.refresh();
                },
                child: state.isLoading && state.reports.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.reports.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.clipboardList,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const Gap(16),
                                Text(
                                  'Belum ada laporan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            state.reports.length +
                            (state.isLoadingMore ? 1 : 0),
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
                          final isSelected = state.selectedReportIds.contains(
                            report.id,
                          );

                          return UniversalReportCard(
                            id: report.id,
                            title: report.title,
                            location: report.location,
                            locationDetail: report.locationDetail,
                            category: report.category,
                            status: report.status,
                            isEmergency: report.isEmergency,
                            elapsedTime: report.elapsed,
                            createdAt: report.createdAt,
                            pausedAt: report.pausedAt,
                            totalPausedDurationSeconds:
                                report.totalPausedDurationSeconds,
                            reporterName: report.reporterName,
                            assignedTo: report.assignedTo,
                            handledBy: report.handledBy,
                            selectionMode: state.isSelectionMode,
                            isSelected: isSelected,
                            showStatus: true,
                            onTap: () {
                              if (state.isSelectionMode) {
                                notifier.toggleSelection(report.id);
                              } else {
                                widget.onReportTap(report.id, report.status);
                              }
                            },
                            onLongPress: () {
                              if (!state.isSelectionMode) {
                                try {
                                  notifier.toggleSelectionMode(report.id);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
        floatingActionButton: widget.floatingActionButton,
        bottomNavigationBar: state.isSelectionMode
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Text(
                        '${state.selectedReportIds.length} Dipilih',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => notifier.exitSelectionMode(),
                        child: const Text('Batal'),
                      ),
                      const Gap(8),
                      ElevatedButton(
                        onPressed: state.selectedReportIds.length < 2
                            ? null
                            : () {
                                // Implement grouping action
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Fitur Grouping (Coming Soon)',
                                    ),
                                  ),
                                );
                                notifier.exitSelectionMode();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.supervisorColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Gabungkan'),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
