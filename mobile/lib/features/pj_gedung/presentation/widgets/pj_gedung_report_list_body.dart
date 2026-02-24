import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/pj_gedung/presentation/providers/pj_gedung_reports_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/core/widgets/custom_date_range_picker.dart';

class PjGedungReportListBody extends ConsumerStatefulWidget {
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

  const PjGedungReportListBody({
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
  });

  @override
  ConsumerState<PjGedungReportListBody> createState() =>
      _PjGedungReportListBodyState();
}

class _PjGedungReportListBodyState
    extends ConsumerState<PjGedungReportListBody> {
  final ScrollController _scrollController = ScrollController();
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(pjGedungReportsProvider(widget.status).notifier)
          .setFilters(
            category: widget.category,
            location: widget.location,
            isEmergency: widget.isEmergency,
            period: widget.period,
            startDate: widget.startDate,
            endDate: widget.endDate,
          );
      _fetchFilterData();
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchFilterData() async {
    try {
      final cats = await reportService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats.map((c) => c['name'] as String).toList()..sort();
        });
      }
    } catch (e) {
      debugPrint('Error fetching filter data: $e');
    }
  }

  @override
  void didUpdateWidget(covariant PjGedungReportListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.category != oldWidget.category ||
        widget.location != oldWidget.location ||
        widget.isEmergency != oldWidget.isEmergency ||
        widget.period != oldWidget.period ||
        widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(pjGedungReportsProvider(widget.status).notifier)
            .setFilters(
              category: widget.category,
              location: widget.location,
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = ref.read(
        pjGedungReportsProvider(widget.status).notifier,
      );
      final state = ref.read(pjGedungReportsProvider(widget.status));
      if (!state.isFetchingMore && state.hasMore) {
        provider.fetchMore();
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

  Widget _buildFilterChip(String label, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(LucideIcons.x, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    final notifier = ref.read(pjGedungReportsProvider(widget.status).notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentState = ref.watch(
            pjGedungReportsProvider(widget.status),
          );

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            notifier.resetFilters();
                            Navigator.pop(context);
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
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(
                              color: AppTheme.pjGedungColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Hanya Darurat'),
                          secondary: Icon(
                            LucideIcons.alertTriangle,
                            color: currentState.emergencyOnly
                                ? AppTheme.emergencyColor
                                : Colors.grey,
                          ),
                          value: currentState.emergencyOnly,
                          onChanged: (value) {
                            notifier.setEmergencyOnly(value);
                            setModalState(() {});
                          },
                        ),
                        const Divider(),
                        const Gap(12),
                        const Text(
                          'Rentang Waktu',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              avatar: const Icon(
                                LucideIcons.calendar,
                                size: 16,
                              ),
                              label: const Text('Hari Ini'),
                              selected: currentState.periodFilter == 'today',
                              onSelected: (selected) {
                                notifier.setPeriodFilter(
                                  selected ? 'today' : null,
                                );
                                setModalState(() {});
                              },
                            ),
                            ChoiceChip(
                              avatar: const Icon(
                                LucideIcons.calendarDays,
                                size: 16,
                              ),
                              label: const Text('Minggu Ini'),
                              selected: currentState.periodFilter == 'week',
                              onSelected: (selected) {
                                notifier.setPeriodFilter(
                                  selected ? 'week' : null,
                                );
                                setModalState(() {});
                              },
                            ),
                            ChoiceChip(
                              avatar: const Icon(
                                LucideIcons.calendarRange,
                                size: 16,
                              ),
                              label: const Text('Bulan Ini'),
                              selected: currentState.periodFilter == 'month',
                              onSelected: (selected) {
                                notifier.setPeriodFilter(
                                  selected ? 'month' : null,
                                );
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                        const Gap(20),
                        const Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ReportStatus.values
                              .where(
                                (s) =>
                                    s.name != 'verifikasi' &&
                                    s.name != 'archived',
                              )
                              .map((status) {
                                final isSelected = currentState.selectedStatuses
                                    .contains(status.name);
                                return FilterChip(
                                  label: Text(status.label),
                                  selected: isSelected,
                                  selectedColor: status.color.withValues(
                                    alpha: 0.2,
                                  ),
                                  checkmarkColor: status.color,
                                  onSelected: (selected) {
                                    final currentSet = Set<String>.from(
                                      currentState.selectedStatuses,
                                    );
                                    if (selected) {
                                      currentSet.add(status.name);
                                    } else {
                                      currentSet.remove(status.name);
                                    }
                                    notifier.setStatuses(currentSet);
                                    setModalState(() {});
                                  },
                                );
                              })
                              .toList(),
                        ),
                        const Gap(20),
                        // Note: Location is typically and inherently tied to PJ Gedung,
                        // but if we want to filter specific rooms/sub-locations, we'd need that data.
                        // Category filtering:
                        const Text(
                          'Kategori',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((cat) {
                            return ChoiceChip(
                              label: Text(cat),
                              selected:
                                  false, // Provider doesn't explicitly store category for PJ yet
                              onSelected: (selected) {
                                // PJ provider setFilters can receive it
                                notifier.setFilters(
                                  category: selected ? cat : null,
                                );
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const Gap(40),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCustomDateRangePicker() async {
    final state = ref.read(pjGedungReportsProvider(widget.status));
    final notifier = ref.read(pjGedungReportsProvider(widget.status).notifier);

    final newDateRange = await CustomDateRangePickerDialog.show(
      context: context,
      initialRange: state.customDateRange,
      themeColor: AppTheme.pjGedungColor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (newDateRange != null) {
      notifier.setDateRange(newDateRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pjGedungReportsProvider(widget.status));
    final notifier = ref.read(pjGedungReportsProvider(widget.status).notifier);

    final hasActiveFilters = currentStateHasFilters(state);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          if (widget.showSearch)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => notifier.setSearchQuery(value),
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
                            color: AppTheme.pjGedungColor,
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
                        color: state.customDateRange != null
                            ? AppTheme.pjGedungColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.customDateRange != null
                              ? AppTheme.pjGedungColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.calendarRange,
                        color: state.customDateRange != null
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
                              ? AppTheme.pjGedungColor
                              : Colors.grey.shade300,
                          width: hasActiveFilters ? 1.5 : 1.0,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.filter,
                        color: hasActiveFilters
                            ? AppTheme.pjGedungColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Active Filters Bar
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
                    if (state.selectedStatuses.isNotEmpty)
                      ...state.selectedStatuses.map((s) {
                        final status = ReportStatus.values.firstWhere(
                          (e) => e.name == s,
                          orElse: () => ReportStatus.pending,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            status.label,
                            status.color,
                            () {
                              final currentSet = Set<String>.from(
                                state.selectedStatuses,
                              );
                              currentSet.remove(s);
                              notifier.setStatuses(currentSet);
                            },
                          ),
                        );
                      }),
                    if (state.emergencyOnly)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          'Darurat',
                          AppTheme.emergencyColor,
                          () {
                            notifier.setEmergencyOnly(false);
                          },
                        ),
                      ),
                    if (state.periodFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          _getPeriodLabel(state.periodFilter!),
                          Colors.blue,
                          () {
                            notifier.setPeriodFilter(null);
                          },
                        ),
                      ),
                    if (state.customDateRange != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          '${DateFormat('dd MMM').format(state.customDateRange!.start)} - ${DateFormat('dd MMM').format(state.customDateRange!.end)}',
                          AppTheme.pjGedungColor,
                          () {
                            notifier.setDateRange(null);
                          },
                        ),
                      ),
                    TextButton(
                      onPressed: () => notifier.resetFilters(),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await notifier.fetchReports(isRefresh: true);
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
                          state.reports.length + (state.isFetchingMore ? 1 : 0),
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
                          elapsedTime: report.elapsed,
                          reporterName: report.reporterName,
                          handledBy: report.handledBy?.join(', '),
                          showStatus: true,
                          onTap: () {
                            widget.onReportTap(report.id, report.status);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  bool currentStateHasFilters(PjGedungReportsState state) {
    return state.selectedStatuses.isNotEmpty ||
        state.emergencyOnly ||
        state.periodFilter != null ||
        state.customDateRange != null;
  }
}
