import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_dashboard_page.dart'; // Import for pjGedungColor

class PJGedungStatisticsPage extends StatelessWidget {
  final String? buildingName;

  const PJGedungStatisticsPage({super.key, this.buildingName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          buildingName != null ? 'Statistik $buildingName' : 'Statistik Gedung',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCard(),
            const Gap(16),
            _buildCategoryBreakdown(),
            const Gap(16),
            _buildDailyTrend(), // Option 1
            const Gap(16),
            _buildMonthlyPerformance(), // Option 3
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                'Ringkasan Minggu Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Chip(
                label: const Text('15 Laporan'),
                backgroundColor: const Color(0xFFD1FAE5), // Green tint
                labelStyle: const TextStyle(
                  color: pjGedungColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Gap(20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBigStat('3', 'Pending', Colors.grey),
              _buildBigStat(
                '2',
                'Verifikasi',
                Colors.amber,
              ), // Updated to Amber
              _buildBigStat('4', 'Proses', Colors.purple),
              _buildBigStat('6', 'Selesai', Colors.green),
            ],
          ),
          const Gap(20),
          const Divider(height: 1),
          const Gap(20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Avg. Penyelesaian',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      '30 menit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 30, width: 1, color: Colors.grey.shade200),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Darurat',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      '2 laporan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBigStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    return _buildSectionCard(
      title: 'Kategori Masalah',
      child: Column(
        children: [
          _buildBarChartItem('Kelistrikan', 0.6, Colors.blue),
          _buildBarChartItem('Sanitasi', 0.8, Colors.orange),
          _buildBarChartItem('AC/Pendingin', 0.4, Colors.red),
          _buildBarChartItem('Lainnya', 0.2, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDailyTrend() {
    return _buildSectionCard(
      title: 'Tren Kesibukan (Harian)',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildTrendBar('Sen', 0.3),
          _buildTrendBar('Sel', 0.5),
          _buildTrendBar('Rab', 0.8), // Peak
          _buildTrendBar('Kam', 0.6),
          _buildTrendBar('Jum', 0.4),
          _buildTrendBar('Sab', 0.2),
          _buildTrendBar('Min', 0.1),
        ],
      ),
    );
  }

  Widget _buildTrendBar(String label, double heightFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: 100 * heightFactor,
          decoration: BoxDecoration(
            color: heightFactor > 0.7
                ? pjGedungColor
                : pjGedungColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Gap(8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: heightFactor > 0.7
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyPerformance() {
    return _buildSectionCard(
      title: 'Timeline Jumlah Laporan',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrendInfo('Bulan Lalu', '12 Laporan', false),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _buildTrendInfo('Bulan Ini', '15 Laporan', true),
            ],
          ),
          const Gap(20),
          // Simplified Line Chart Representation for Timeline
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLinePoint(0.4, 'Minggu 1'),
                _buildLinePoint(0.6, 'Minggu 2'),
                _buildLinePoint(0.5, 'Minggu 3'),
                _buildLinePoint(0.8, 'Minggu 4'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendInfo(String label, String value, bool isUp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Gap(4),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Gap(4),
            Icon(
              isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              size: 16,
              color: isUp
                  ? Colors.red
                  : Colors
                        .green, // Red often means "more reports" (bad for building health)
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinePoint(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: pjGedungColor, width: 3),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: 60 * heightFactor,
          color: pjGedungColor.withOpacity(0.5),
        ),
        const Gap(8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBarChartItem(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          Text(
            '${(percentage * 10).toInt()}', // Mock value count
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Gap(16),
          child,
        ],
      ),
    );
  }
}
