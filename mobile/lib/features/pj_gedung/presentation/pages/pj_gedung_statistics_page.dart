import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/statistics_widgets.dart';

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
            StatsSectionCard(
              title: 'Kategori Masalah',
              child: Column(
                children: [
                  StatsBarChartItem(
                    label: 'Kelistrikan',
                    percentage: 0.6,
                    color: Colors.blue,
                    valueSuffix: '6',
                  ),
                  StatsBarChartItem(
                    label: 'Sanitasi',
                    percentage: 0.8,
                    color: Colors.orange,
                    valueSuffix: '8',
                  ),
                  StatsBarChartItem(
                    label: 'AC/Pendingin',
                    percentage: 0.4,
                    color: Colors.red,
                    valueSuffix: '4',
                  ),
                  StatsBarChartItem(
                    label: 'Lainnya',
                    percentage: 0.2,
                    color: Colors.grey,
                    valueSuffix: '2',
                  ),
                ],
              ),
            ),
            const Gap(16),
            StatsSectionCard(
              title: 'Tren Kesibukan (Harian)',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatsTrendBar(
                    label: 'Sen',
                    heightFactor: 0.3,
                    activeColor: AppTheme.pjGedungColor,
                  ),
                  StatsTrendBar(
                    label: 'Sel',
                    heightFactor: 0.5,
                    activeColor: AppTheme.pjGedungColor,
                  ),
                  StatsTrendBar(
                    label: 'Rab',
                    heightFactor: 0.8,
                    activeColor: AppTheme.pjGedungColor,
                  ),
                  StatsTrendBar(
                    label: 'Kam',
                    heightFactor: 0.6,
                    activeColor: AppTheme.pjGedungColor,
                  ),
                  StatsTrendBar(
                    label: 'Jum',
                    heightFactor: 0.4,
                    activeColor: AppTheme.pjGedungColor,
                  ),
                  StatsTrendBar(
                    label: 'Sab',
                    heightFactor: 0.2,
                    activeColor: AppTheme.pjGedungColor,
                  ),
                  StatsTrendBar(
                    label: 'Min',
                    heightFactor: 0.1,
                    activeColor: AppTheme.pjGedungColor,
                  ),
                ],
              ),
            ),
            const Gap(16),
            StatsSectionCard(
              title: 'Timeline Jumlah Laporan',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatsTrendInfo(
                        label: 'Bulan Lalu',
                        value: '12 Laporan',
                        isUp: false,
                        emphasizeUpAsBad: true,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade200,
                      ),
                      StatsTrendInfo(
                        label: 'Bulan Ini',
                        value: '15 Laporan',
                        isUp: true,
                        emphasizeUpAsBad: true,
                      ),
                    ],
                  ),
                  const Gap(20),
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
            ),
            const Gap(32),
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
                'Ringkasan Minggu Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Chip(
                label: const Text('15 Laporan'),
                backgroundColor: const Color(0xFFD1FAE5),
                labelStyle: const TextStyle(
                  color: AppTheme.pjGedungColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Gap(20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatsBigStatItem(
                value: '3',
                label: 'Pending',
                color: Colors.grey,
              ),
              StatsBigStatItem(
                value: '2',
                label: 'Verifikasi',
                color: Colors.amber,
              ),
              StatsBigStatItem(
                value: '4',
                label: 'Proses',
                color: Colors.purple,
              ),
              StatsBigStatItem(
                value: '6',
                label: 'Selesai',
                color: Colors.green,
              ),
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

  Widget _buildLinePoint(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.pjGedungColor, width: 3),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: 60 * heightFactor,
          color: AppTheme.pjGedungColor.withValues(alpha: 0.5),
        ),
        const Gap(8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
