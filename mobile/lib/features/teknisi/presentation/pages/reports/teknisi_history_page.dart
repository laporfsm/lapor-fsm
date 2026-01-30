import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';

/// History page showing completed reports with filters
class TeknisiHistoryPage extends StatefulWidget {
  const TeknisiHistoryPage({super.key});

  @override
  State<TeknisiHistoryPage> createState() => _TeknisiHistoryPageState();
}

class _TeknisiHistoryPageState extends State<TeknisiHistoryPage> {
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = true;
  List<Report> _completedReports = [];
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        // Fetch Selesai & Approved reports
        final results = await Future.wait([
          reportService.getStaffReports(role: 'technician', status: 'selesai'),
          reportService.getStaffReports(role: 'technician', status: 'approved'),
        ]);

        if (mounted) {
          setState(() {
            final selesai = results[0]
                .map((json) => Report.fromJson(json))
                .toList();
            final approved = results[1]
                .map((json) => Report.fromJson(json))
                .toList();

            _completedReports = [...selesai, ...approved];

            // Sort by most recent first
            _completedReports.sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
            );

            // Extract categories for filter
            _categories =
                _completedReports.map((r) => r.category).toSet().toList()
                  ..sort();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching history reports: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Report> get _filteredReports {
    var reports = List<Report>.from(_completedReports);

    // Apply category filter
    if (_selectedCategory != null) {
      reports = reports.where((r) => r.category == _selectedCategory).toList();
    }

    // Apply date range filter
    if (_selectedDateRange != null) {
      reports = reports.where((r) {
        return r.createdAt.isAfter(_selectedDateRange!.start) &&
            r.createdAt.isBefore(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }
    return reports;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayReports = _filteredReports;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat'),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible:
                  _selectedCategory != null || _selectedDateRange != null,
              child: const Icon(LucideIcons.filter),
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Filters
          if (_selectedCategory != null || _selectedDateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  if (_selectedCategory != null)
                    _buildFilterChip(
                      _selectedCategory!,
                      () => setState(() => _selectedCategory = null),
                    ),
                  if (_selectedDateRange != null) ...[
                    if (_selectedCategory != null) const Gap(8),
                    _buildFilterChip(
                      _formatDateRange(_selectedDateRange!),
                      () => setState(() => _selectedDateRange = null),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedCategory = null;
                      _selectedDateRange = null;
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),

          // Reports List
          Expanded(
            child: displayReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.history,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const Gap(16),
                        Text(
                          'Tidak ada riwayat',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayReports.length,
                      itemBuilder: (context, index) {
                        final report = displayReports[index];

                        // Calculate handling time (completed - started - paused)
                        Duration? handlingTime;
                        Duration? holdTime;

                        if (report.handlingStartedAt != null &&
                            report.completedAt != null) {
                          final totalTime = report.completedAt!.difference(
                            report.handlingStartedAt!,
                          );
                          holdTime = Duration(
                            seconds: report.totalPausedDurationSeconds,
                          );
                          handlingTime = totalTime - holdTime;
                        }

                        return UniversalReportCard(
                          id: report.id,
                          title: report.title,
                          location: report.building,
                          locationDetail: report.locationDetail,
                          category: report.category,
                          status: report.status,
                          isEmergency: report.isEmergency,
                          handlingTime: handlingTime,
                          holdTime: holdTime,
                          showStatus: true,
                          showTimer: false,
                          onTap: () =>
                              context.push('/teknisi/report/${report.id}'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              LucideIcons.x,
              size: 14,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTimeRange range) {
    final start = '${range.start.day}/${range.start.month}';
    final end = '${range.end.day}/${range.end.month}';
    return '$start - $end';
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
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
                const Text(
                  'Filter Riwayat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  children: [
                    ..._categories.map(
                      (cat) => ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? cat : null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
                const Gap(20),

                // Date Range Filter
                const Text(
                  'Rentang Tanggal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Gap(8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );
                    if (range != null) {
                      setState(() => _selectedDateRange = range);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(LucideIcons.calendar),
                  label: Text(
                    _selectedDateRange != null
                        ? _formatDateRange(_selectedDateRange!)
                        : 'Pilih Tanggal',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
