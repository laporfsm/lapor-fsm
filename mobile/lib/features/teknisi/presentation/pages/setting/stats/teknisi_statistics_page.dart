import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/statistics_widgets.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/services/auth_service.dart';

class TeknisiStatisticsPage extends ConsumerStatefulWidget {
  const TeknisiStatisticsPage({super.key});

  @override
  ConsumerState<TeknisiStatisticsPage> createState() =>
      _TeknisiStatisticsPageState();
}

class _TeknisiStatisticsPageState extends ConsumerState<TeknisiStatisticsPage> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _selectedPeriod = 'weekly';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await authService.getCurrentUser();
    if (user == null || user['staffId'] == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final data = await reportService.getTechnicianStatistics(
      user['staffId'].toString(),
      period: _selectedPeriod,
    );

    if (mounted) {
      setState(() {
        _stats = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Statistik Pekerjaan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _stats == null
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Gagal memuat data statistik'),
                              const Gap(16),
                              ElevatedButton(
                                onPressed: _loadData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildFilterDropdown(),
                          const Gap(16),
                          _buildSummaryCard(_stats!['summary'] ?? []),
                          const Gap(16),
                          StatsSectionCard(
                            title: 'Berdasarkan Kategori',
                            child: _buildCategoryList(),
                          ),
                          const Gap(16),
                          StatsSectionCard(
                            title: 'Tren Aktivitas (7 Hari Terakhir)',
                            child: _buildWeeklyTrend(),
                          ),
                          const Gap(32),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, color: Colors.grey),
          items: const [
            DropdownMenuItem(value: 'weekly', child: Text('Minggu Ini')),
            DropdownMenuItem(value: 'monthly', child: Text('Bulan Ini')),
            DropdownMenuItem(value: 'all', child: Text('Semua Data')),
          ],
          onChanged: (value) {
            if (value != null && value != _selectedPeriod) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<dynamic> summaryItems) {
    String title = 'Ringkasan Laporan';
    if (_selectedPeriod == 'weekly') title = 'Ringkasan Minggu Ini';
    if (_selectedPeriod == 'monthly') title = 'Ringkasan Bulan Ini';
    if (_selectedPeriod == 'all') title = 'Ringkasan Semua Waktu';

    int totalReports = 0;
    for (var item in summaryItems) {
      totalReports += (item['value'] as num).toInt();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Chip(
                label: Text('$totalReports Pekerjaan'),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                labelStyle: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Gap(20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: summaryItems.map((item) {
              return StatsBigStatItem(
                label: item['label'],
                value: item['value'].toString(),
                color: _getStatusColor(item['color'] ?? item['label']),
              );
            }).toList(),
          ),
          const Gap(16),
          const Text(
            'Statistik terupdate berdasarkan data sistem.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final categoriesData = _stats?['categories'] as List? ?? [];
    if (categoriesData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Belum ada data kategori',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    int maxCount = 0;
    for (var cat in categoriesData) {
      final count = (cat['count'] as num).toInt();
      if (count > maxCount) maxCount = count;
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.indigo,
    ];

    return Column(
      children: List.generate(categoriesData.length, (index) {
        final cat = categoriesData[index];
        final count = (cat['count'] as num).toInt();
        return StatsBarChartItem(
          label: cat['name'] ?? 'Lainnya',
          percentage: maxCount > 0 ? count / maxCount : 0,
          color: colors[index % colors.length],
          valueSuffix: count.toString(),
        );
      }),
    );
  }

  Widget _buildWeeklyTrend() {
    final trendData = _stats?['dailyTrends'] as List? ?? [];
    if (trendData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Belum ada data tren',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    int maxVal = 0;
    for (var t in trendData) {
      final val = (t['value'] as num).toInt();
      if (val > maxVal) maxVal = val;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: trendData.map((t) {
        final val = (t['value'] as num).toInt();
        return StatsTrendBar(
          label: t['day'] ?? '',
          heightFactor: maxVal > 0 ? val / maxVal : 0.05,
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String colorOrLabel) {
    switch (colorOrLabel.toLowerCase()) {
      case 'grey':
      case 'pending':
        return Colors.grey;
      case 'blue':
      case 'terverifikasi':
      case 'penanganan':
        return Colors.blue;
      case 'green':
      case 'selesai':
      case 'approved':
        return Colors.green;
      case 'red':
      case 'ditolak':
        return Colors.red;
      case 'orange':
      case 'diproses':
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }
}
