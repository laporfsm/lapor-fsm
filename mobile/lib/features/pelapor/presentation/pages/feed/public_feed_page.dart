import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class PublicFeedPage extends StatefulWidget {
  const PublicFeedPage({super.key});

  @override
  State<PublicFeedPage> createState() => _PublicFeedPageState();
}

class _PublicFeedPageState extends State<PublicFeedPage> {
  String _selectedCategory = 'Semua';
  String _selectedBuilding = 'Semua';
  final _searchController = TextEditingController();

  final List<String> _categories = ['Semua', 'Emergency', 'Maintenance', 'Kebersihan'];
  final List<String> _buildings = ['Semua', 'Gedung A', 'Gedung B', 'Gedung C', 'Gedung D', 'Gedung E'];

  // Mock data
  final List<Map<String, dynamic>> _reports = [
    {
      'id': 1,
      'title': 'AC Mati di Ruang E102',
      'category': 'Maintenance',
      'building': 'Gedung E',
      'status': 'Penanganan',
      'time': '2 jam lalu',
      'isEmergency': false,
    },
    {
      'id': 2,
      'title': 'Kebocoran Pipa Toilet',
      'category': 'Maintenance',
      'building': 'Gedung C',
      'status': 'Verifikasi',
      'time': '30 menit lalu',
      'isEmergency': false,
    },
    {
      'id': 3,
      'title': 'Kebakaran di Lab Kimia',
      'category': 'Emergency',
      'building': 'Gedung D',
      'status': 'Penanganan',
      'time': '5 menit lalu',
      'isEmergency': true,
    },
    {
      'id': 4,
      'title': 'Sampah Menumpuk Area Parkir',
      'category': 'Kebersihan',
      'building': 'Gedung A',
      'status': 'Pending',
      'time': '1 jam lalu',
      'isEmergency': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredReports {
    return _reports.where((r) {
      final matchCategory = _selectedCategory == 'Semua' || r['category'] == _selectedCategory;
      final matchBuilding = _selectedBuilding == 'Semua' || r['building'] == _selectedBuilding;
      final matchSearch = _searchController.text.isEmpty ||
          r['title'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBuilding,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _buildings.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (v) => setState(() => _selectedBuilding = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Reports List
          Expanded(
            child: _filteredReports.isEmpty
                ? const Center(child: Text('Tidak ada laporan ditemukan'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReports.length,
                    separatorBuilder: (_, __) => const Gap(12),
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      return _ReportCard(
                        report: report,
                        onTap: () => context.push('/report-detail/${report['id']}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  Color get _statusColor {
    switch (report['status']) {
      case 'Verifikasi':
        return Colors.orange;
      case 'Penanganan':
        return Colors.blue;
      case 'Selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: report['isEmergency'] == true
              ? Border.all(color: Colors.red, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: report['isEmergency'] == true
                    ? Colors.red.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                report['isEmergency'] == true ? LucideIcons.siren : LucideIcons.fileText,
                color: report['isEmergency'] == true ? Colors.red : AppTheme.primaryColor,
              ),
            ),
            const Gap(12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Gap(4),
                  Text(
                    '${report['building']} • ${report['time']}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report['status'],
                style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
