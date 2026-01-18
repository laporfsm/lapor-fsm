import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class SupervisorTechnicianListPage extends StatefulWidget {
  const SupervisorTechnicianListPage({super.key});

  @override
  State<SupervisorTechnicianListPage> createState() =>
      _SupervisorTechnicianListPageState();
}

class _SupervisorTechnicianListPageState
    extends State<SupervisorTechnicianListPage> {
  // Mock Data
  final List<Map<String, dynamic>> _technicians = [
    {
      'id': '1',
      'name': 'Budi Santoso',
      'status': 'online',
      'role': 'Teknisi Listrik',
      'handled': 12,
      'completed': 10,
      'rating': 4.8,
    },
    {
      'id': '2',
      'name': 'Ahmad Hidayat',
      'status': 'offline',
      'role': 'Teknisi Sipil',
      'handled': 8,
      'completed': 8,
      'rating': 4.5,
    },
    {
      'id': '3',
      'name': 'Rudi Hartono',
      'status': 'busy',
      'role': 'Teknisi AC',
      'handled': 15,
      'completed': 12,
      'rating': 4.9,
    },
    {
      'id': '4',
      'name': 'Dewi Lestari',
      'status': 'online',
      'role': 'Teknisi Jaringan',
      'handled': 5,
      'completed': 4,
      'rating': 4.7,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Log Aktivitas Teknisi'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _technicians.length,
        separatorBuilder: (context, index) => const Gap(12),
        itemBuilder: (context, index) {
          final tech = _technicians[index];
          return _buildTechnicianCard(context, tech);
        },
      ),
    );
  }

  Widget _buildTechnicianCard(BuildContext context, Map<String, dynamic> tech) {
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
                      /*
                      Icon(LucideIcons.star, size: 14, color: Colors.amber),
                      const Gap(4),
                      Text(
                        tech['rating'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Gap(12),
                      */
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
