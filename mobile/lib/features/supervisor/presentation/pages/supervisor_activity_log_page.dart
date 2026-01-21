import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class SupervisorActivityLogPage extends StatelessWidget {
  const SupervisorActivityLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for Activity Logs
    final List<Map<String, dynamic>> technicians = [
      {
        'id': '1',
        'name': 'Budi Santoso',
        'status': 'online',
        'role': 'Teknisi Listrik',
        'handled': 12,
        'completed': 10,
      },
      {
        'id': '2',
        'name': 'Ahmad Hidayat',
        'status': 'offline',
        'role': 'Teknisi Sipil',
        'handled': 8,
        'completed': 8,
      },
      {
        'id': '3',
        'name': 'Rudi Hartono',
        'status': 'busy',
        'role': 'Teknisi AC',
        'handled': 15,
        'completed': 12,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: technicians.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final tech = technicians[index];
        return _buildActivityCard(context, tech);
      },
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> tech) {
    Color statusColor;
    switch (tech['status']) {
      case 'online':
        statusColor = Colors.green;
        break;
      case 'busy':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        context.push('/supervisor/technician/${tech['id']}');
      },
      child: Container(
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
        child: Row(
          children: [
            // Avatar with Status Badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.supervisorColor.withOpacity(0.1),
                  child: Text(
                    tech['name'].toString().substring(0, 1),
                    style: const TextStyle(
                      color: AppTheme.supervisorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tech['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    tech['role'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      _buildMiniStat(
                        LucideIcons.checkCircle2,
                        '${tech['completed']} Selesai',
                        Colors.green,
                      ),
                      const Gap(12),
                      _buildMiniStat(
                        LucideIcons.briefcase,
                        '${tech['handled']} Total',
                        AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(LucideIcons.chevronRight, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
