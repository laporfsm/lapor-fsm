import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

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
            _buildCategoryBreakdown(),
            const Gap(16),
            _buildBuildingBreakdown(),
            const Gap(16),
            _buildTechnicianPerformance(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBigStat('8', 'Pending', Colors.grey),
              _buildBigStat('3', 'Verifikasi', Colors.blue),
              _buildBigStat('5', 'Proses', Colors.orange),
              _buildBigStat('140', 'Selesai', Colors.green),
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
      title: 'Berdasarkan Kategori',
      child: Column(
        children: [
          _buildBarChartItem('Kelistrikan', 0.8, Colors.blue),
          _buildBarChartItem('Sipil & Bangunan', 0.6, Colors.orange),
          _buildBarChartItem('Infrastruktur', 0.4, Colors.red),
          _buildBarChartItem('Lainnya', 0.2, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBuildingBreakdown() {
    return _buildSectionCard(
      title: 'Berdasarkan Gedung',
      child: Column(
        children: [
          _buildBarChartItem('Gedung A', 0.9, Colors.teal),
          _buildBarChartItem('Gedung B', 0.5, Colors.teal),
          _buildBarChartItem('Gedung C', 0.3, Colors.teal),
        ],
      ),
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
            '${(percentage * 100).toInt()}%',
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

  Widget _buildTechnicianPerformance() {
    return _buildSectionCard(
      title: 'Performa Teknisi (Top 3)',
      child: Column(
        children: [
          _buildTechItem('Budi Santoso', '4.8', '45 Selesai'),
          _buildTechItem('Ahmad Hidayat', '4.7', '32 Selesai'),
          _buildTechItem('Rudi Hartono', '4.5', '28 Selesai'),
        ],
      ),
    );
  }

  Widget _buildTechItem(String name, String rating, String done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.supervisorColor.withOpacity(0.1),
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
