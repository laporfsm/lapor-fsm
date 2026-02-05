import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/statistics_widgets.dart';

class SupervisorStatisticsPage extends StatelessWidget {
  const SupervisorStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Statistik Laporan'),
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
            const StatsSectionCard(
              title: 'Berdasarkan Kategori',
              child: Column(
                children: [
                  StatsBarChartItem(
                    label: 'Listrik',
                    percentage: 0.8,
                    color: Colors.blue,
                  ),
                  StatsBarChartItem(
                    label: 'Bangunan',
                    percentage: 0.6,
                    color: Colors.orange,
                  ),
                  StatsBarChartItem(
                    label: 'Infrastruktur',
                    percentage: 0.4,
                    color: Colors.red,
                  ),
                  StatsBarChartItem(
                    label: 'Lainnya',
                    percentage: 0.2,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            const Gap(16),
            StatsSectionCard(
              title: 'Gedung Paling Bermasalah (Top 3)',
              child: Column(
                children: [
                  StatsBarChartItem(
                    label: 'Gedung A',
                    percentage: 0.9,
                    color: Colors.teal,
                    onTap: () => context.push(
                      Uri(
                        path: '/pj-gedung/statistics',
                        queryParameters: {'buildingName': 'Gedung A'},
                      ).toString(),
                    ),
                  ),
                  StatsBarChartItem(
                    label: 'Gedung B',
                    percentage: 0.5,
                    color: Colors.teal,
                    onTap: () => context.push(
                      Uri(
                        path: '/pj-gedung/statistics',
                        queryParameters: {'buildingName': 'Gedung B'},
                      ).toString(),
                    ),
                  ),
                  StatsBarChartItem(
                    label: 'Gedung C',
                    percentage: 0.3,
                    color: Colors.teal,
                    onTap: () => context.push(
                      Uri(
                        path: '/pj-gedung/statistics',
                        queryParameters: {'buildingName': 'Gedung C'},
                      ).toString(),
                    ),
                  ),
                  const Gap(8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/supervisor/buildings'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Lihat Semua Gedung'),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            const StatsSectionCard(
              title: 'Tren Kesibukan (Harian)',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatsTrendBar(
                    label: 'Sen',
                    heightFactor: 0.3,
                    activeColor: AppTheme.supervisorColor,
                  ),
                  StatsTrendBar(
                    label: 'Sel',
                    heightFactor: 0.7,
                    activeColor: AppTheme.supervisorColor,
                  ),
                  StatsTrendBar(
                    label: 'Rab',
                    heightFactor: 0.5,
                    activeColor: AppTheme.supervisorColor,
                  ),
                  StatsTrendBar(
                    label: 'Kam',
                    heightFactor: 0.8,
                    activeColor: AppTheme.supervisorColor,
                  ),
                  StatsTrendBar(
                    label: 'Jum',
                    heightFactor: 0.6,
                    activeColor: AppTheme.supervisorColor,
                  ),
                  StatsTrendBar(
                    label: 'Sab',
                    heightFactor: 0.4,
                    activeColor: AppTheme.supervisorColor,
                  ),
                  StatsTrendBar(
                    label: 'Min',
                    heightFactor: 0.2,
                    activeColor: AppTheme.supervisorColor,
                  ),
                ],
              ),
            ),
            const Gap(16),
            StatsSectionCard(
              title: 'Timeline & Prediksi',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StatsTrendInfo(
                        label: 'Bulan Lalu',
                        value: '120 Laporan',
                        isUp: false,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade200,
                      ),
                      const StatsTrendInfo(
                        label: 'Bulan Ini',
                        value: '145 Laporan',
                        isUp: true,
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
                        _buildLinePoint(0.8, 'Minggu 3'),
                        _buildLinePoint(0.5, 'Minggu 4'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            StatsSectionCard(
              title: 'Performa Teknisi (Top 3)',
              child: Column(
                children: [
                  _buildTechItem('Budi Santoso', '4.8', '45 Selesai'),
                  _buildTechItem('Ahmad Hidayat', '4.7', '32 Selesai'),
                  _buildTechItem('Rudi Hartono', '4.5', '28 Selesai'),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Minggu Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Chip(
                label: Text('23 Laporan'),
                backgroundColor: Color(0xFFE0E7FF),
                labelStyle: TextStyle(
                  color: AppTheme.supervisorColor,
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
                value: '8',
                label: 'Pending',
                color: Colors.grey,
              ),
              StatsBigStatItem(
                value: '3',
                label: 'Verifikasi',
                color: Colors.blue,
              ),
              StatsBigStatItem(
                value: '5',
                label: 'Proses',
                color: Colors.orange,
              ),
              StatsBigStatItem(
                value: '140',
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
                      'Avg. Penanganan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      '45 menit',
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
                      '12 laporan',
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
            border: Border.all(color: AppTheme.supervisorColor, width: 3),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: 60 * heightFactor,
          color: AppTheme.supervisorColor.withValues(alpha: 0.5),
        ),
        const Gap(8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTechItem(String name, String rating, String done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.supervisorColor.withValues(alpha: 0.1),
            child: Text(
              name[0],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.supervisorColor,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                done,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
              Row(
                children: [
                  const Icon(LucideIcons.star, size: 10, color: Colors.amber),
                  const Gap(2),
                  Text(
                    rating,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
