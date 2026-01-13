import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class ReportDetailPage extends StatelessWidget {
  final String reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    // Mock data based on ID
    final report = {
      'id': reportId,
      'title': 'AC Mati di Ruang E102',
      'category': 'Infrastruktur Kelas',
      'building': 'Gedung E',
      'description': 'AC di ruang E102 tidak menyala sejak pagi. Sudah dicoba hidupkan berkali-kali tetapi tidak ada respon. Ruangan menjadi sangat panas dan tidak kondusif untuk perkuliahan.',
      'status': 'Penanganan',
      'createdAt': '13 Jan 2026, 08:30',
      'reporter': 'Sulhan Fuadi',
      'latitude': -6.998576,
      'longitude': 110.423188,
    };

    final timeline = [
      {'status': 'Laporan Dibuat', 'time': '13 Jan 2026, 08:30', 'done': true},
      {'status': 'Verifikasi', 'time': '13 Jan 2026, 08:45', 'done': true},
      {'status': 'Penanganan', 'time': '13 Jan 2026, 09:00', 'done': true, 'current': true},
      {'status': 'Selesai', 'time': '-', 'done': false},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: Center(
                child: Icon(LucideIcons.image, size: 64, color: Colors.grey.shade400),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.wrench, size: 14, color: Colors.blue),
                        Gap(6),
                        Text('Penanganan', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Gap(16),

                  // Title
                  Text(
                    report['title'] as String,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Gap(12),

                  // Info Row
                  Row(
                    children: [
                      _InfoChip(icon: LucideIcons.tag, text: report['category'] as String),
                      const Gap(12),
                      _InfoChip(icon: LucideIcons.building, text: report['building'] as String),
                    ],
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 14, color: Colors.grey.shade600),
                      const Gap(4),
                      Text(report['createdAt'] as String, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                  const Gap(20),

                  // Description
                  const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Gap(8),
                  Text(report['description'] as String, style: const TextStyle(height: 1.5)),
                  const Gap(24),

                  // Timeline
                  const Text('Status Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Gap(12),
                  ...timeline.map((t) => _TimelineItem(
                    status: t['status'] as String,
                    time: t['time'] as String,
                    isDone: t['done'] as bool,
                    isCurrent: t['current'] == true,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const Gap(4),
          Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String status;
  final String time;
  final bool isDone;
  final bool isCurrent;

  const _TimelineItem({
    required this.status,
    required this.time,
    required this.isDone,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppTheme.primaryColor : Colors.grey.shade300,
                border: isCurrent ? Border.all(color: AppTheme.primaryColor, width: 3) : null,
              ),
              child: isDone
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
            Container(
              width: 2,
              height: 40,
              color: isDone ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
          ],
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? Colors.black : Colors.grey,
                ),
              ),
              Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const Gap(20),
            ],
          ),
        ),
      ],
    );
  }
}
