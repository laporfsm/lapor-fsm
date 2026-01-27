import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class SupervisorActivityLogPage extends StatefulWidget {
  const SupervisorActivityLogPage({super.key});

  @override
  State<SupervisorActivityLogPage> createState() =>
      _SupervisorActivityLogPageState();
}

class _SupervisorActivityLogPageState extends State<SupervisorActivityLogPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _technicianLogs = [
    {
      'id': 1,
      'actor': 'Budi Teknisi',
      'role': 'Teknisi',
      'action': 'memulai penanganan',
      'target': 'AC Lab Komputer',
      'time': '5 menit lalu',
      'icon': LucideIcons.wrench,
      'color': Colors.orange,
    },
    {
      'id': 3,
      'actor': 'Andi Teknisi',
      'role': 'Teknisi',
      'action': 'menyelesaikan laporan',
      'target': 'Pipa Toilet',
      'time': '30 menit lalu',
      'icon': LucideIcons.checkCheck,
      'color': Colors.blue,
    },
    {
      'id': 6,
      'actor': 'Eko Teknisi',
      'role': 'Teknisi',
      'action': 'meminta sparepart',
      'target': 'Kabel LAN',
      'time': '3 jam lalu',
      'icon': LucideIcons.package,
      'color': Colors.purple,
    },
  ];

  final List<Map<String, dynamic>> _pjLogs = [
    {
      'id': 2,
      'actor': 'PJ Gedung A',
      'role': 'PJ Gedung',
      'action': 'memverifikasi laporan',
      'target': 'Lampu Koridor',
      'time': '15 menit lalu',
      'icon': LucideIcons.checkCircle,
      'color': Colors.green,
    },
    {
      'id': 5,
      'actor': 'PJ Gedung B',
      'role': 'PJ Gedung',
      'action': 'memverifikasi laporan',
      'target': 'Air Keran Macet',
      'time': '2 jam lalu',
      'icon': LucideIcons.checkCircle,
      'color': Colors.green,
    },
    {
      'id': 4,
      'actor': 'Siti Pelapor',
      'role': 'PJ Gedung',
      'action': 'menolak laporan',
      'target': 'Kursi Patah (Duplikat)',
      'time': '1 hari lalu',
      'icon': LucideIcons.xCircle,
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Teknisi'),
              Tab(text: 'PJ Gedung'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildLogList(_technicianLogs), _buildLogList(_pjLogs)],
          ),
        ),
      ],
    );
  }

  Widget _buildLogList(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.history, size: 64, color: Colors.grey.shade300),
            const Gap(16),
            Text(
              'Belum ada aktivitas',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        return _buildLogCard(logs[index]);
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: (log['color'] as Color).withOpacity(0.1),
            child: Icon(log['icon'], color: log['color'], size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log['actor'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        log['role'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    children: [
                      TextSpan(text: log['action']),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: log['target'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const Gap(4),
                    Text(
                      log['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
