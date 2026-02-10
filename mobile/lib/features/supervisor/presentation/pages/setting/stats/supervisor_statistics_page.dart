import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/statistics_widgets.dart';
import 'package:mobile/core/services/report_service.dart';

class SupervisorStatisticsPage extends ConsumerStatefulWidget {
  const SupervisorStatisticsPage({super.key});

  @override
  ConsumerState<SupervisorStatisticsPage> createState() =>
      _SupervisorStatisticsPageState();
}

class _SupervisorStatisticsPageState
    extends ConsumerState<SupervisorStatisticsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final data = await reportService.getSupervisorStatistics();
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
        title: const Text('Statistik Laporan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stats == null
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
                          onPressed: _fetchStats,
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
                    _buildSummaryCard(_stats!['summary']),
                    const Gap(16),
                    StatsSectionCard(
                      title: 'Berdasarkan Kategori',
                      child: Column(
                        children: (_stats!['categories'] as List).map((c) {
                          return StatsBarChartItem(
                            label: c['label'],
                            percentage: (c['percentage'] as num).toDouble(),
                            color: _getCategoryColor(c['label']),
                            valueSuffix: '${c['count']}',
                          );
                        }).toList(),
                      ),
                    ),
                    const Gap(16),
                    StatsSectionCard(
                      title: 'Lokasi Paling Bermasalah',
                      child: Column(
                        children: [
                          ...(_stats!['buildings'] as List).map((b) {
                            return StatsBarChartItem(
                              label: b['name'],
                              percentage: _calculateBuildingPercentage(
                                b['count'],
                              ),
                              color: Colors.teal,
                              valueSuffix: '${b['count']}',
                              onTap: () => context.push(
                                Uri(
                                  path: '/pj-gedung/statistics',
                                  queryParameters: {'buildingName': b['name']},
                                ).toString(),
                              ),
                            );
                          }),
                          const Gap(8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () =>
                                  context.push('/supervisor/buildings'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Lihat Semua Lokasi'),
                            ),
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
                        children: (_stats!['dailyTrends'] as List).map((t) {
                          return StatsTrendBar(
                            label: t['day'],
                            heightFactor: _calculateTrendFactor(t['value']),
                            activeColor: AppTheme.supervisorColor,
                          );
                        }).toList(),
                      ),
                    ),
                    const Gap(16),
                    StatsSectionCard(
                      title: 'Performa Teknisi (Top)',
                      child: Column(
                        children: (_stats!['technicians'] as List).map((t) {
                          return _buildTechItem(
                            t['name'],
                            t['completedCount'].toString(),
                            t['status'],
                          );
                        }).toList(),
                      ),
                    ),
                    const Gap(32),
                  ],
                ),
              ),
      ),
    );
  }

  double _calculateBuildingPercentage(int count) {
    final buildings = _stats!['buildings'] as List;
    if (buildings.isEmpty) return 0;
    final maxCount = buildings.first['count'] as int;
    return maxCount > 0 ? count / maxCount : 0;
  }

  double _calculateTrendFactor(int value) {
    final trends = _stats!['dailyTrends'] as List;
    if (trends.isEmpty) return 0;
    int maxValue = 1;
    for (var t in trends) {
      if ((t['value'] as int) > maxValue) maxValue = t['value'];
    }
    return maxValue > 0 ? value / maxValue : 0;
  }

  Color _getCategoryColor(String label) {
    switch (label.toLowerCase()) {
      case 'listrik':
        return Colors.blue;
      case 'bangunan':
        return Colors.orange;
      case 'infrastruktur':
        return Colors.red;
      case 'it':
      case 'jaringan':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSummaryCard(List summary) {
    int total = 0;
    for (var s in summary) {
      total += (s['value'] as int);
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
              const Text(
                'Ringkasan Minggu Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Chip(
                label: Text('$total Laporan'),
                backgroundColor: const Color(0xFFE0E7FF),
                labelStyle: const TextStyle(
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
            children: summary.map((s) {
              return StatsBigStatItem(
                value: s['value'].toString(),
                label: s['label'],
                color: _getStatusColor(s['label']),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String label) {
    switch (label.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'diproses':
        return Colors.blue;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Widget _buildTechItem(String name, String completedCount, String status) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: status == 'Bekerja' ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Selesai',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                completedCount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.supervisorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
