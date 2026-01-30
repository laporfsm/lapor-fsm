import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/theme.dart';

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  List<Report> _myReports = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedFilter = "Semua"; // "Semua", "Aktif", "Selesai", "Ditolak"
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ["Semua", "Aktif", "Selesai", "Ditolak"];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final reportsData = await reportService.getMyReports(
          user['id'].toString(),
          role: user['role'],
        );
        if (mounted) {
          setState(() {
            _myReports = reportsData.map((json) {
              try {
                return Report.fromJson(json);
              } catch (e) {
                return null;
              }
            }).whereType<Report>().toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil riwayat: $e')),
        );
      }
    }
  }

  List<Report> get _filteredReports {
    return _myReports.where((report) {
      // 1. Search Filter
      final matchesSearch = report.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.building.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (report.locationDetail?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      if (!matchesSearch) return false;

      // 2. Category Filter
      switch (_selectedFilter) {
        case "Aktif":
          return report.status != ReportStatus.approved && 
                 report.status != ReportStatus.selesai && 
                 report.status != ReportStatus.ditolak &&
                 report.status != ReportStatus.archived;
        case "Selesai":
          return report.status == ReportStatus.selesai || 
                 report.status == ReportStatus.approved ||
                 report.status == ReportStatus.archived;
        case "Ditolak":
          return report.status == ReportStatus.ditolak;
        default:
          return true; // "Semua"
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Riwayat Laporan Saya',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchAndFilter(),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchReports,
                    child: _filteredReports.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = _filteredReports[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: UniversalReportCard(
                                  id: report.id,
                                  title: report.title,
                                  category: report.category,
                                  location: report.building,
                                  locationDetail: report.locationDetail,
                                  status: report.status,
                                  elapsedTime: DateTime.now().difference(report.createdAt),
                                  showStatus: true,
                                  compact: false,
                                  onTap: () => context.push('/report-detail/${report.id}'),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari laporan atau lokasi...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(LucideIcons.xCircle, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const Gap(12),
          // Simplified Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filters.map((filter) => _buildFilterChip(filter)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = label);
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty || _selectedFilter != "Semua" 
                ? LucideIcons.searchX 
                : LucideIcons.inbox,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const Gap(16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != "Semua"
                ? 'Tidak ada hasil ditemukan'
                : 'Belum ada laporan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const Gap(4),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != "Semua"
                ? 'Coba gunakan kueri atau filter lain'
                : 'Laporan Anda akan muncul di sini',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          if (_searchQuery.isNotEmpty || _selectedFilter != "Semua") ...[
            const Gap(16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = "";
                  _selectedFilter = "Semua";
                });
              },
              child: const Text('Reset Filter'),
            ),
          ],
        ],
      ),
    );
  }
}
