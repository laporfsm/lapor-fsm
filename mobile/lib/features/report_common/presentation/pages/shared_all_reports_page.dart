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
  });

  @override
  State<SharedAllReportsPage> createState() => _SharedAllReportsPageState();
}

class _SharedAllReportsPageState extends State<SharedAllReportsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Report> _reports = [];
  bool _isLoading = true;

  Set<ReportStatus> _selectedStatuses = {};
  String? _selectedCategory;
  String? _selectedBuilding;
  bool _emergencyOnly = false;

  String? _selectedPeriod; // 'today', 'week', 'month'
  DateTimeRange? _selectedDateRange; // Custom date range

  List<String> _categoryNames = [];

  @override
  void initState() {
    super.initState();
    _initFilters();
    _fetchData();
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
    await Future.wait([_fetchReports(), _fetchCategories()]);
    if (mounted) setState(() => _isLoading = false);
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

  Future<void> _fetchReports() async {
    try {
      final reportsData = await reportService.getPublicReports(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _selectedStatuses.isNotEmpty
            ? _selectedStatuses.map((s) => s.name).join(',')
            : widget.allowedStatuses?.map((s) => s.name).join(','),
        category: _selectedCategory,
        building: _selectedBuilding,
        isEmergency: _emergencyOnly,
        period: _selectedPeriod,
        startDate: _selectedDateRange?.start.toIso8601String(),
        endDate: _selectedDateRange?.end.toIso8601String(),
      );

      debugPrint('Fetched ${reportsData.length} reports from API');

      if (mounted) {
        setState(() {
          _reports = reportsData.map((json) {
            final r = Report.fromJson(json);
            debugPrint('Mapping Report ID: ${r.id}, Title: ${r.title}');
            return r;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories => _categoryNames;

  List<String> get _buildings {
    // Static list of major buildings for FSM
    return [
      'Gedung A',
      'Gedung B',
      'Gedung C',
      'Gedung D',
      'Gedung E',
      'Gedung F',
      'Lab Terpadu',
      'Perpustakaan',
      'Dekanat',
    ];
  }

  bool get _hasActiveFilters {
    bool hasDateFilter = false;
    if (widget.enableDateFilter) {
      hasDateFilter = _selectedPeriod != null || _selectedDateRange != null;
    }
    return _selectedStatuses.isNotEmpty ||
        _selectedCategory != null ||
        _selectedBuilding != null ||
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
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(s.label, s.color, () {
                        setState(() => _selectedStatuses.remove(s));
                        _fetchReports();
                      }),
                    ),
                  ),
                  if (_selectedCategory != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        _selectedCategory!,
                        Colors.purple,
                        () {
                          setState(() => _selectedCategory = null);
                          _fetchReports();
                        },
                      ),
                    ),
                  if (_selectedBuilding != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        _selectedBuilding!,
                        Colors.teal,
                        () {
                          setState(() => _selectedBuilding = null);
                          _fetchReports();
                        },
                      ),
                    ),
                  if (_emergencyOnly)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        'Darurat',
                        AppTheme.emergencyColor,
                        () {
                          setState(() => _emergencyOnly = false);
                          _fetchReports();
                        },
                      ),
                    ),
                  if (_selectedPeriod != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        _getPeriodLabel(_selectedPeriod!),
                        Colors.blue,
                        () {
                          setState(() => _selectedPeriod = null);
                          _fetchReports();
                        },
                      ),
                    ),
                  if (_selectedDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                        widget.appBarColor,
                        () {
                          setState(() => _selectedDateRange = null);
                          _fetchReports();
                        },
                      ),
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
            '${_reports.length} laporan ditemukan',
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
                          padding: const EdgeInsets.all(16),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            return UniversalReportCard(
                              id: report.id,
                              title: report.title,
                              location: report.building,
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
        ),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
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
        ),
        body: content,
        floatingActionButton: widget.floatingActionButton,
      );
    } else {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: content, // No AppBar
        floatingActionButton: widget.floatingActionButton,
      );
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

  void _clearAllFilters() {
    setState(() {
      _selectedStatuses.clear();
      _selectedCategory = null;
      _selectedBuilding = null;
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Gap(20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Laporan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedStatuses.clear();
                              _selectedCategory = null;
                              _selectedBuilding = null;
                              _emergencyOnly = false;
                              _selectedPeriod = null;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const Gap(20),

                    // Emergency Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hanya Darurat'),
                      secondary: Icon(
                        LucideIcons.alertTriangle,
                        color: _emergencyOnly
                            ? AppTheme.emergencyColor
                            : Colors.grey,
                      ),
                      value: _emergencyOnly,
                      onChanged: (value) {
                        setModalState(() => _emergencyOnly = value);
                        setState(() => _emergencyOnly = value);
                      },
                    ),
                    const Divider(),
                    const Gap(12),

                    // Period Filter
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
                          avatar: const Icon(LucideIcons.calendar, size: 16),
                          label: const Text('Hari Ini'),
                          selected: _selectedPeriod == 'today',
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedPeriod = selected ? 'today' : null;
                            });
                            setState(() {});
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(
                            LucideIcons.calendarDays,
                            size: 16,
                          ),
                          label: const Text('Minggu Ini'),
                          selected: _selectedPeriod == 'week',
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedPeriod = selected ? 'week' : null;
                            });
                            setState(() {});
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(
                            LucideIcons.calendarRange,
                            size: 16,
                          ),
                          label: const Text('Bulan Ini'),
                          selected: _selectedPeriod == 'month',
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedPeriod = selected ? 'month' : null;
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const Gap(20),

                    // Status Filter
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (widget.allowedStatuses != null
                                  ? widget.allowedStatuses!
                                  : ReportStatus.values)
                              .map((status) {
                                final isSelected = _selectedStatuses.contains(
                                  status,
                                );
                                return FilterChip(
                                  label: Text(status.label),
                                  selected: isSelected,
                                  selectedColor: status.color.withValues(
                                    alpha: 0.2,
                                  ),
                                  checkmarkColor: status.color,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        _selectedStatuses.add(status);
                                      } else {
                                        _selectedStatuses.remove(status);
                                      }
                                    });
                                    setState(() {});
                                  },
                                );
                              })
                              .toList(),
                    ),
                    const Gap(20),

                    // Category Filter
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
                          selected: _selectedCategory == cat,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedCategory = selected ? cat : null;
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const Gap(20),

                    // Building Filter
                    const Text(
                      'Gedung',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildings.map((building) {
                        return ChoiceChip(
                          label: Text(building),
                          selected: _selectedBuilding == building,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedBuilding = selected ? building : null;
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const Gap(20),
                  ],
                ),
              );
            },
          );
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
        _selectedPeriod = null; // Clear preset period if custom range selected
      });
      _fetchReports();
    }
  }
}
