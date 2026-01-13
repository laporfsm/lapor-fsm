import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class ReportHistoryPage extends StatelessWidget {
  const ReportHistoryPage({super.key});

  // Mock data - user's own reports
  List<Map<String, dynamic>> get _myReports => [
    {
      'id': 101,
      'title': 'Lampu Koridor Mati',
      'category': 'Kelistrikan',
      'building': 'Gedung E',
      'status': 'Selesai',
      'createdAt': '10 Jan 2026, 14:30',
    },
    {
      'id': 102,
      'title': 'Kebocoran AC di Lab',
      'category': 'Infrastruktur Kelas',
      'building': 'Gedung C',
      'status': 'Penanganan',
      'createdAt': '12 Jan 2026, 09:15',
    },
    {
      'id': 103,
      'title': 'Kaca Jendela Retak',
      'category': 'Sipil & Bangunan',
      'building': 'Gedung B',
      'status': 'Verifikasi',
      'createdAt': '13 Jan 2026, 08:00',
    },
  ];

  Color _statusColor(String status) {
    switch (status) {
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Verifikasi':
        return LucideIcons.clock;
      case 'Penanganan':
        return LucideIcons.wrench;
      case 'Selesai':
        return LucideIcons.checkCircle;
      default:
        return LucideIcons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Laporan Saya'),
        backgroundColor: Colors.white,
      ),
      body: _myReports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.inbox, size: 64, color: Colors.grey.shade300),
                  const Gap(16),
                  const Text('Belum ada laporan', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _myReports.length,
              separatorBuilder: (_, __) => const Gap(12),
              itemBuilder: (context, index) {
                final report = _myReports[index];
                return GestureDetector(
                  onTap: () => context.push('/report-detail/${report['id']}'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                report['title'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(report['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_statusIcon(report['status']), size: 14, color: _statusColor(report['status'])),
                                  const Gap(4),
                                  Text(
                                    report['status'],
                                    style: TextStyle(
                                      color: _statusColor(report['status']),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Row(
                          children: [
                            Icon(LucideIcons.tag, size: 14, color: Colors.grey.shade500),
                            const Gap(4),
                            Text(report['category'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const Gap(16),
                            Icon(LucideIcons.building, size: 14, color: Colors.grey.shade500),
                            const Gap(4),
                            Text(report['building'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                        const Gap(8),
                        Row(
                          children: [
                            Icon(LucideIcons.calendar, size: 14, color: Colors.grey.shade500),
                            const Gap(4),
                            Text(report['createdAt'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
