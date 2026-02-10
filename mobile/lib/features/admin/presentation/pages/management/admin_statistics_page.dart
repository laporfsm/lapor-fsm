import 'package:flutter/material.dart'; // Re-triggering compile
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/statistics_widgets.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:intl/intl.dart'; // Import for NumberFormat

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await adminService.getStatistics();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.adminColor,
        title: const Text(
          'Statistik Lengkap',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatsSectionCard(
                    title: 'Pertumbuhan User',
                    child: _buildUserGrowthChart(),
                  ),
                  const Gap(24),
                  StatsSectionCard(
                    title: 'Aktivitas User',
                    child: _buildActivityCards(),
                  ),
                  const Gap(24),
                  StatsSectionCard(
                    title: 'Traffic Penggunaan Aplikasi',
                    child: _buildAppUsageChart(),
                  ),
                  const Gap(24),
                  StatsSectionCard(
                    title: 'Distribusi User',
                    child: _buildUserDistributionChart(),
                  ),
                  const Gap(24),
                  StatsSectionCard(
                    title: 'Volume Laporan',
                    child: _buildReportVolumeChart(),
                  ),
                  const Gap(32),
                ],
              ),
            ),
    );
  }

  // 1. User Growth (Line Chart)
  Widget _buildUserGrowthChart() {
    final List points = _data?['userGrowth'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registrasi User Baru (30 Hari Terakhir)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const Gap(20),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.white,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      return LineTooltipItem(
                        '${barSpot.y.toInt()}',
                        const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value >= 0 && value < points.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            points[value.toInt()]['date'],
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
                  lineBarsData: [
                LineChartBarData(
                  spots: points.asMap().entries.map((e) {
                    final val = e.value['value'];
                    final double y = (val is num ? val : double.tryParse(val.toString()) ?? 0).toDouble();
                    return FlSpot(
                      e.key.toDouble(),
                      y,
                    );
                  }).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: false, // Clean look like design
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. Activity Cards
  Widget _buildActivityCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: LucideIcons.zap,
            iconColor: Colors.orange,
            value: '${_data?['activeUsers'] ?? 0}',
            label: 'User Aktif (Hari Ini)',
          ),
        ),
        const Gap(16),
        Expanded(
          child: _buildStatCard(
            icon: LucideIcons.logIn,
            iconColor: Colors.green,
            value: NumberFormat('#,###').format(_data?['totalLogin'] ?? 0),
            label: 'Total Login (Minggu Ini)',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const Gap(12),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // 3. App Usage (Bar Chart)
  Widget _buildAppUsageChart() {
    final List data = _data?['appUsage'] ?? [];

    // Check if data is empty or all values are zero
    final hasActivity = data.isNotEmpty && data.any((item) {
      final val = item['value'];
      final double value = (val is num ? val : double.tryParse(val.toString()) ?? 0).toDouble();
      return value > 0;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Traffic Penggunaan Aplikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const Gap(20),
        if (!hasActivity)
          Container(
            height: 180,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.barChart2,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const Gap(12),
                Text(
                  'Belum ada aktivitas minggu ini',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 60,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}',
                        TextStyle(
                          color: rod.color ?? Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              data[value.toInt()]['day'],
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  final val = e.value['value'];
                  final double y = (val is num ? val : double.tryParse(val.toString()) ?? 0).toDouble();
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: y,
                        color: Colors.purple.shade300,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  // 4. User Distribution (Pie Chart)
  Widget _buildUserDistributionChart() {
    final Map<String, dynamic> distribution = _data?['userDistribution'] ?? {};
    final colors = [Colors.blue, Colors.orange, Colors.indigo, Colors.purple];

    int index = 0;
    final sections = distribution.entries.map((e) {
      final color = colors[index % colors.length];
      index++;
      final val = e.value;
      final double value = (val is num ? val : double.tryParse(val.toString()) ?? 0).toDouble();
      
      return PieChartSectionData(
        color: color,
        value: value,
        title: '${value.toInt()}', // Show count instead of % if preferred, or calc %
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 80,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Komposisi Role User',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 0,
                    centerSpaceRadius: 0,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: distribution.entries.map((e) {
                    final i = distribution.keys.toList().indexOf(e.key);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: colors[i % colors.length],
                          ),
                          const Gap(8),
                          Text(e.key, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Report Volume (Bar Chart Group)
  Widget _buildReportVolumeChart() {
    final List data = _data?['reportVolume'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Masuk vs Selesai',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const Gap(20),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 50,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()}',
                      TextStyle(
                        color: rod.color ?? Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value >= 0 && value < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            data[value.toInt()]['dept'],
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: (e.value['in'] as int).toDouble(),
                      color: Colors.blue,
                      width: 8,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    BarChartRodData(
                      toY: (e.value['out'] as int).toDouble(),
                      color: Colors.green,
                      width: 8,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                  barsSpace: 4,
                );
              }).toList(),
            ),
          ),
        ),
        const Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegend(Colors.blue, 'Masuk'),
            const Gap(16),
            _buildLegend(Colors.green, 'Selesai'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const Gap(6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
