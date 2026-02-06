import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/statistics_widgets.dart';
import 'package:mobile/core/services/report_service.dart';

class PJGedungStatisticsPage extends StatefulWidget {
  final String? locationName;

  const PJGedungStatisticsPage({super.key, this.locationName});

  @override
  State<PJGedungStatisticsPage> createState() => _PJGedungStatisticsPageState();
}

class _PJGedungStatisticsPageState extends State<PJGedungStatisticsPage> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await reportService.getPJStatistics(
      locationName: widget.locationName,
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
        title: Text(
          widget.locationName != null
              ? 'Statistik ${widget.locationName}'
              : 'Statistik Lokasi',
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    const Gap(16),
                    StatsSectionCard(
                      title: 'Kategori Masalah',
                      child: _buildCategoryList(),
                    ),
                    const Gap(16),
                    StatsSectionCard(
                      title: 'Tren Kesibukan (7 Hari Terakhir)',
                      child: _buildWeeklyTrend(),
                    ),
                    const Gap(16),
                    StatsSectionCard(
                      title: 'Timeline Jumlah Laporan',
                      child: _buildComparison(),
                    ),
                    const Gap(32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final thisMonth = _stats?['thisMonth'] ?? 0;
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
              const Text(
                'Ringkasan Bulan Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Chip(
                label: Text('$thisMonth Laporan'),
                backgroundColor: const Color(0xFFD1FAE5),
                labelStyle: const TextStyle(
                  color: AppTheme.pjLokasiColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Gap(20),
          // Additional summary details could go here
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

    // Find max for percentage calculation
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
          label: cat['label'] ?? 'Lainnya',
          percentage: maxCount > 0 ? count / maxCount : 0,
          color: colors[index % colors.length],
          valueSuffix: count.toString(),
        );
      }),
    );
  }

  Widget _buildWeeklyTrend() {
    final trendData = _stats?['weeklyTrend'] as List? ?? [];
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

    // Find max for height calculation
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
          heightFactor: maxVal > 0 ? val / maxVal : 0.1,
          activeColor: AppTheme.pjLokasiColor,
        );
      }).toList(),
    );
  }

  Widget _buildComparison() {
    final thisMonth = _stats?['thisMonth'] ?? 0;
    final monthlyProgress = _stats?['monthlyProgress'] as List? ?? [0, 0, 0, 0];
    int maxProg = 0;
    for (var val in monthlyProgress) {
      final v = (val as num).toInt();
      if (v > maxProg) maxProg = v;
    }

    final lastMonth = _stats?['lastMonth'] ?? 0;
    final isUp = (thisMonth as num) > (lastMonth as num);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StatsTrendInfo(
              label: 'Bulan Lalu',
              value: '$lastMonth Laporan',
              isUp: false,
              emphasizeUpAsBad: true,
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            StatsTrendInfo(
              label: 'Bulan Ini',
              value: '$thisMonth Laporan',
              isUp: isUp,
              emphasizeUpAsBad: true,
            ),
          ],
        ),
        const Gap(20),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSimpleBar(
                maxProg > 0
                    ? (monthlyProgress[0] as num).toInt() / maxProg
                    : 0.05,
                'Minggu 1',
              ),
              _buildSimpleBar(
                maxProg > 0
                    ? (monthlyProgress[1] as num).toInt() / maxProg
                    : 0.05,
                'Minggu 2',
              ),
              _buildSimpleBar(
                maxProg > 0
                    ? (monthlyProgress[2] as num).toInt() / maxProg
                    : 0.05,
                'Minggu 3',
              ),
              _buildSimpleBar(
                maxProg > 0
                    ? (monthlyProgress[3] as num).toInt() / maxProg
                    : 0.05,
                'Minggu 4+',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleBar(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.pjLokasiColor, width: 3),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: 60 * heightFactor,
          color: AppTheme.pjLokasiColor.withValues(alpha: 0.5),
        ),
        const Gap(8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
