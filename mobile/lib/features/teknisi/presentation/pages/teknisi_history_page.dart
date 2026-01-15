import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class TeknisiHistoryPage extends StatelessWidget {
  const TeknisiHistoryPage({super.key});

  // TODO: [BACKEND] Replace with API call to get technician's completed reports
  List<Map<String, dynamic>> get _completedReports => [
    {
      'id': 101,
      'title': 'AC Mati di Lab Komputer',
      'category': 'Kelistrikan',
      'building': 'Gedung G, Lt 2',
      'status': 'Selesai',
      'completedAt': '12 Jan 2026, 15:30',
      'duration': '45 menit',
      'handledBy': ['Budi Santoso'],
      'supervisedBy': 'Pak Joko Widodo',
    },
    {
      'id': 102,
      'title': 'Kebocoran Pipa Toilet',
      'category': 'Sipil & Bangunan',
      'building': 'Gedung E, Lt 1',
      'status': 'Selesai',
      'completedAt': '11 Jan 2026, 10:00',
      'duration': '1 jam 20 menit',
      'handledBy': ['Budi Santoso', 'Ahmad Hidayat'],
      'supervisedBy': 'Pak Joko Widodo',
    },
    {
      'id': 103,
      'title': 'Lampu Koridor Mati',
      'category': 'Kelistrikan',
      'building': 'Gedung C, Lt 3',
      'status': 'Selesai',
      'completedAt': '10 Jan 2026, 14:15',
      'duration': '30 menit',
      'handledBy': ['Ahmad Hidayat'],
      'supervisedBy': 'Pak Susilo',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas'),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _completedReports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.inbox,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const Gap(16),
                  const Text(
                    'Belum ada laporan selesai',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _completedReports.length,
              separatorBuilder: (_, __) => const Gap(12),
              itemBuilder: (context, index) {
                final report = _completedReports[index];
                return GestureDetector(
                  onTap: () => context.push('/teknisi/report/${report['id']}'),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.checkCircle,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Gap(4),
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.tag,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const Gap(4),
                                      Text(
                                        report['category'],
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Gap(12),
                        const Divider(height: 1),
                        const Gap(12),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.building,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const Gap(4),
                            Expanded(
                              child: Text(
                                report['building'],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Icon(
                              LucideIcons.timer,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const Gap(4),
                            Text(
                              report['duration'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const Gap(4),
                            Text(
                              report['completedAt'],
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        // TK-012: Show teknisi and supervisor info
                        if (report['handledBy'] != null) ...[
                          const Gap(8),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.wrench,
                                size: 14,
                                color: AppTheme.secondaryColor,
                              ),
                              const Gap(4),
                              Expanded(
                                child: Text(
                                  'Teknisi: ${(report['handledBy'] as List).join(', ')}',
                                  style: TextStyle(
                                    color: AppTheme.secondaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (report['supervisedBy'] != null) ...[
                          const Gap(4),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.userCheck,
                                size: 14,
                                color: AppTheme.primaryColor,
                              ),
                              const Gap(4),
                              Expanded(
                                child: Text(
                                  'Supervisor: ${report['supervisedBy']}',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
