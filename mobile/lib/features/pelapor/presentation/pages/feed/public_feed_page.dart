import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/core/report.dart';
import 'package:mobile/core/data/mock_report_data.dart';

class PublicFeedPage extends StatefulWidget {
  const PublicFeedPage({super.key});

  @override
  State<PublicFeedPage> createState() => _PublicFeedPageState();
}

class _PublicFeedPageState extends State<PublicFeedPage> {
  String _selectedCategory = 'Semua';
  String _selectedBuilding = 'Semua';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Emergency',
    'Maintenance',
    'Kebersihan',
  ];
  final List<String> _buildings = [
    'Semua',
    'Gedung A',
    'Gedung B',
    'Gedung C',
    'Gedung D',
    'Gedung E',
  ];

  // Use centralized mock data for consistency
  List<Report> get _reports => [
    MockReportData.getReportOrDefault('1'),
    MockReportData.getReportOrDefault('2'),
    MockReportData.getReportOrDefault('3'),
    MockReportData.getReportOrDefault('4'),
  ];

  List<Report> get _filteredReports {
    return _reports.where((r) {
      final matchCategory =
          _selectedCategory == 'Semua' || r.category == _selectedCategory;
      final matchBuilding =
          _selectedBuilding == 'Semua' || r.building == _selectedBuilding;
      final matchSearch =
          _searchController.text.isEmpty ||
          r.title.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchCategory && matchBuilding && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Public Feed'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari laporan...',
                    prefixIcon: const Icon(LucideIcons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const Gap(12),
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v!),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBuilding,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _buildings
                            .map(
                              (b) => DropdownMenuItem(value: b, child: Text(b)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedBuilding = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reports List using shared ReportCard
          Expanded(
            child: _filteredReports.isEmpty
                ? const Center(child: Text('Tidak ada laporan ditemukan'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      return ReportCard(
                        report: report,
                        viewerRole: UserRole.pelapor,
                        showTimer: false,
                        onTap: () =>
                            context.push('/report-detail/${report.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
