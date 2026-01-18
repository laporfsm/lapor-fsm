import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';
import 'package:intl/intl.dart';

class SupervisorTechnicianDetailPage extends StatefulWidget {
  final String technicianId;

  const SupervisorTechnicianDetailPage({super.key, required this.technicianId});

  @override
  State<SupervisorTechnicianDetailPage> createState() =>
      _SupervisorTechnicianDetailPageState();
}

class _SupervisorTechnicianDetailPageState
    extends State<SupervisorTechnicianDetailPage> {
  // Mock Data
  late Map<String, dynamic> _technician;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTechnicianData();
  }

  void _loadTechnicianData() {
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _technician = {
            'id': widget.technicianId,
            'name': 'Budi Santoso',
            'role': 'Teknisi Listrik',
            'email': 'budi.santoso@staff.undip.ac.id',
            'phone': '081234567890',
            'status': 'online',
            'lastActive': DateTime.now(),
            'stats': {'completed': 45, 'inProgress': 2, 'avgTime': '45 menit'},
            'logs': [
              {
                'time': DateTime.now().subtract(const Duration(minutes: 15)),
                'action': 'Menyelesaikan Laporan',
                'description': 'Laporan #102: AC Mati di Ruang 201',
                'type': 'complete', // complete, process, check_in
              },
              {
                'time': DateTime.now().subtract(const Duration(hours: 1)),
                'action': 'Memulai Penanganan',
                'description': 'Laporan #102: AC Mati di Ruang 201',
                'type': 'process',
              },
              {
                'time': DateTime.now().subtract(const Duration(hours: 2)),
                'action': 'Login Aplikasi',
                'description': 'Masuk pada pukul 08:00 WIB',
                'type': 'check_in',
              },
              {
                'time': DateTime.now().subtract(
                  const Duration(days: 1, hours: 2),
                ),
                'action': 'Menyelesaikan Laporan',
                'description': 'Laporan #98: Lampu taman mati',
                'type': 'complete',
              },
              {
                'time': DateTime.now().subtract(
                  const Duration(days: 1, hours: 5),
                ),
                'action': 'Login Aplikasi',
                'description': 'Masuk pada pukul 07:55 WIB',
                'type': 'check_in',
              },
            ],
          };
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detail Aktivitas'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
        child: Column(
          children: [
            // Profile Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.supervisorColor.withOpacity(0.1),
                    child: Text(
                      _technician['name'].substring(0, 1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.supervisorColor,
                      ),
                    ),
                  ),
                  const Gap(16),
                  Text(
                    _technician['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _technician['role'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const Gap(24),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        'Selesai',
                        _technician['stats']['completed'].toString(),
                      ),
                      _buildVerticalDivider(),
                      _buildStatItem(
                        'Proses',
                        _technician['stats']['inProgress'].toString(),
                      ),
                      _buildVerticalDivider(),
                      _buildStatItem(
                        'Avg. Waktu',
                        _technician['stats']['avgTime'],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Gap(16),

            // Timeline Logs
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Log Aktivitas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Gap(16),
                  ...(_technician['logs'] as List).map(
                    (log) => _buildLogItem(log),
                  ),
                ],
              ),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    Color iconColor;
    IconData icon;
    Color bgColor;

    switch (log['type']) {
      case 'complete':
        iconColor = Colors.green;
        icon = LucideIcons.checkCircle2;
        bgColor = Colors.green.withOpacity(0.1);
        break;
      case 'process':
        iconColor = Colors.orange;
        icon = LucideIcons.wrench;
        bgColor = Colors.orange.withOpacity(0.1);
        break;
      case 'check_in':
        iconColor = AppTheme.primaryColor;
        icon = LucideIcons.logIn;
        bgColor = AppTheme.primaryColor.withOpacity(0.1);
        break;
      default:
        iconColor = Colors.grey;
        icon = LucideIcons.info;
        bgColor = Colors.grey.withOpacity(0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          SizedBox(
            width: 50,
            child: Text(
              DateFormat('HH:mm').format(log['time']),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Icon Line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              Container(width: 2, height: 40, color: Colors.grey.shade100),
            ],
          ),
          const Gap(12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['action'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Gap(2),
                Text(
                  log['description'],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Gap(4),
                Text(
                  DateFormat('dd MMM yyyy').format(log['time']),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
