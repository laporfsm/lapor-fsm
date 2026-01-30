import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';

/// History page showing completed reports with advanced filters
class TeknisiHistoryPage extends StatefulWidget {
  const TeknisiHistoryPage({super.key});

  @override
  State<TeknisiHistoryPage> createState() => _TeknisiHistoryPageState();
}

class _TeknisiHistoryPageState extends State<TeknisiHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = true;
  List<Report> _reports = [];
  List<String> _categories = [];
  int? _currentStaffId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final user = await authService.getCurrentUser();
    if (user != null) {
      _currentStaffId = user['staffId'];
    }
    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (_currentStaffId == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await reportService.getStaffReports(
        role: 'technician',
        status: 'selesai,approved', // Only history
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory,
        assignedTo: _currentStaffId,
        startDate: _selectedDateRange?.start.toIso8601String(),
        endDate: _selectedDateRange?.end.toIso8601String(),
      );

      final fetchedReports = results
          .map((json) => Report.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _reports = fetchedReports;
          // Sort by most recent
          _reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Fetch categories if empty
          if (_categories.isEmpty) {
            _fetchCategories();
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await reportService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories.map((c) => c['name'] as String).toList()
            ..sort();
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDateRange = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _fetchData();
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null ||
      _selectedDateRange != null ||
      _searchQuery.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Pekerjaan'),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Header ala "Semua Laporan"
          _buildHeader(),

          // Results count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_reports.length} laporan selesai',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  if (_hasActiveFilters) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: _clearFilters,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Reset Filter',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: _reports.isEmpty
                        ? _buildEmptyState()
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
                                elapsedTime: DateTime.now().difference(
                                  report.createdAt,
                                ),
                                showStatus: true,
                                showTimer: false,
                                onTap: () async {
                                  await context.push(
                                    '/teknisi/report/${report.id}',
                                  );
                                  _fetchData();
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (val) {
                      setState(() => _searchQuery = val);
                      _fetchData();
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari laporan...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const Gap(12),
              BouncingButton(
                onTap: _showFilterSheet,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasActiveFilters
                          ? AppTheme.teknisiColor
                          : Colors.grey.shade300,
                      width: _hasActiveFilters ? 1.5 : 1.0,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.filter,
                    color: _hasActiveFilters
                        ? AppTheme.teknisiColor
                        : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedDateRange != null || _selectedCategory != null) ...[
            const Gap(12),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedDateRange != null)
                    _buildSmallChip(
                      '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                      () {
                        setState(() => _selectedDateRange = null);
                        _fetchData();
                      },
                    ),
                  if (_selectedCategory != null) ...[
                    const Gap(8),
                    _buildSmallChip(_selectedCategory!, () {
                      setState(() => _selectedCategory = null);
                      _fetchData();
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.teknisiColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.teknisiColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.teknisiColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              LucideIcons.x,
              size: 12,
              color: AppTheme.teknisiColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.history, size: 64, color: Colors.grey.shade300),
          const Gap(16),
          Text(
            _hasActiveFilters
                ? 'Tidak ada laporan dengan filter ini'
                : 'Belum ada riwayat laporan',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
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
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
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
                    const Gap(24),
                    const Text(
                      'Filter Riwayat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(24),
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(
                              () => _selectedCategory = selected ? cat : null,
                            );
                            setState(
                              () => _selectedCategory = selected ? cat : null,
                            );
                          },
                          selectedColor: AppTheme.teknisiColor.withValues(
                            alpha: 0.2,
                          ),
                          checkmarkColor: AppTheme.teknisiColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.teknisiColor
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const Gap(24),
                    const Text(
                      'Rentang Tanggal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(12),
                    InkWell(
                      onTap: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                          initialDateRange: _selectedDateRange,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppTheme.teknisiColor,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (range != null) {
                          setModalState(() => _selectedDateRange = range);
                          setState(() => _selectedDateRange = range);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 20,
                              color: AppTheme.teknisiColor,
                            ),
                            const Gap(12),
                            Text(
                              _selectedDateRange != null
                                  ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
                                  : 'Pilih rentang tanggal',
                              style: TextStyle(
                                color: _selectedDateRange != null
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _fetchData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.teknisiColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Terapkan Filter'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
