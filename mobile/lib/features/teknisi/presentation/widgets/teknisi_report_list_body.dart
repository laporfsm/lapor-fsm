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
import 'package:mobile/core/widgets/custom_date_range_picker.dart';

class TeknisiReportListBody extends ConsumerStatefulWidget {
  final String status;
  final Function(String reportId, ReportStatus status) onReportTap;
  final Color? themeColor;
  final bool showSearch;

  const TeknisiReportListBody({
    super.key,
    required this.status,
    required this.onReportTap,
    this.themeColor,
    this.showSearch = true,
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
    _fetchFilterData();
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
    final notifier = ref.read(teknisiReportsProvider(widget.status).notifier);
    final themeColor = widget.themeColor ?? AppTheme.secondaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentState = ref.watch(teknisiReportsProvider(widget.status));

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
                            notifier.clearFilters();
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
                          child: Text(
                            'Tutup',
                            style: TextStyle(
                              color: themeColor,
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
                            color: (currentState.isEmergency ?? false)
                                ? AppTheme.emergencyColor
                                : Colors.grey,
                          ),
                          value: currentState.isEmergency ?? false,
                          onChanged: (value) {
                            notifier.setFilters(
                              category: currentState.category,
                              location: currentState.location,
                              isEmergency: value,
                              period: currentState.period,
                              startDate: currentState.startDate,
                              endDate: currentState.endDate,
                            );
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
                              selected: currentState.period == 'today',
                              onSelected: (selected) {
                                notifier.setFilters(
                                  category: currentState.category,
                                  location: currentState.location,
                                  isEmergency: currentState.isEmergency,
                                  period: selected ? 'today' : null,
                                  startDate: null,
                                  endDate: null,
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
                              selected: currentState.period == 'week',
                              onSelected: (selected) {
                                notifier.setFilters(
                                  category: currentState.category,
                                  location: currentState.location,
                                  isEmergency: currentState.isEmergency,
                                  period: selected ? 'week' : null,
                                  startDate: null,
                                  endDate: null,
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
                              selected: currentState.period == 'month',
                              onSelected: (selected) {
                                notifier.setFilters(
                                  category: currentState.category,
                                  location: currentState.location,
                                  isEmergency: currentState.isEmergency,
                                  period: selected ? 'month' : null,
                                  startDate: null,
                                  endDate: null,
                                );
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                        const Gap(20),
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
                              selected: currentState.category == cat,
                              onSelected: (selected) {
                                notifier.setFilters(
                                  category: selected ? cat : null,
                                  location: currentState.location,
                                  isEmergency: currentState.isEmergency,
                                  period: currentState.period,
                                  startDate: currentState.startDate,
                                  endDate: currentState.endDate,
                                );
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const Gap(20),
                        const Text(
                          'Lokasi',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _locations.map((loc) {
                            return ChoiceChip(
                              label: Text(loc),
                              selected: currentState.location == loc,
                              onSelected: (selected) {
                                notifier.setFilters(
                                  category: currentState.category,
                                  location: selected ? loc : null,
                                  isEmergency: currentState.isEmergency,
                                  period: currentState.period,
                                  startDate: currentState.startDate,
                                  endDate: currentState.endDate,
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
        category: state.category,
        location: state.location,
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

    final hasActiveFilters =
        state.category != null ||
        state.location != null ||
        (state.isEmergency ?? false) ||
        state.period != null ||
        state.startDate != null;

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
                    if (state.category != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          state.category!,
                          Colors.purple,
                          () {
                            notifier.setFilters(
                              category: null,
                              location: state.location,
                              isEmergency: state.isEmergency,
                              period: state.period,
                              startDate: state.startDate,
                              endDate: state.endDate,
                            );
                          },
                        ),
                      ),
                    if (state.location != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          state.location!,
                          Colors.teal,
                          () {
                            notifier.setFilters(
                              category: state.category,
                              location: null,
                              isEmergency: state.isEmergency,
                              period: state.period,
                              startDate: state.startDate,
                              endDate: state.endDate,
                            );
                          },
                        ),
                      ),
                    if (state.isEmergency ?? false)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          'Darurat',
                          AppTheme.emergencyColor,
                          () {
                            notifier.setFilters(
                              category: state.category,
                              location: state.location,
                              isEmergency: false,
                              period: state.period,
                              startDate: state.startDate,
                              endDate: state.endDate,
                            );
                          },
                        ),
                      ),
                    if (state.period != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          _getPeriodLabel(state.period!),
                          Colors.blue,
                          () {
                            notifier.setFilters(
                              category: state.category,
                              location: state.location,
                              isEmergency: state.isEmergency,
                              period: null,
                              startDate: state.startDate,
                              endDate: state.endDate,
                            );
                          },
                        ),
                      ),
                    if (state.startDate != null && state.endDate != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          '${DateFormat('dd MMM').format(state.startDate!)} - ${DateFormat('dd MMM').format(state.endDate!)}',
                          themeColor,
                          () {
                            notifier.setFilters(
                              category: state.category,
                              location: state.location,
                              isEmergency: state.isEmergency,
                              period: state.period,
                              startDate: null,
                              endDate: null,
                            );
                          },
                        ),
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
                        handledBy: report.handledBy?.join(', '),
                        elapsedTime: DateTime.now().difference(
                          report.createdAt,
                        ),
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
