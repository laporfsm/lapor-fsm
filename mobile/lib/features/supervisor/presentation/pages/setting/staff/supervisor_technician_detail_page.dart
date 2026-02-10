import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/supervisor/data/services/supervisor_staff_service.dart';

class SupervisorTechnicianDetailPage extends StatefulWidget {
  final String technicianId;

  const SupervisorTechnicianDetailPage({super.key, required this.technicianId});

  @override
  State<SupervisorTechnicianDetailPage> createState() =>
      _SupervisorTechnicianDetailPageState();
}

class _SupervisorTechnicianDetailPageState
    extends State<SupervisorTechnicianDetailPage> {
  // Use Service
  final _supervisorStaffService = SupervisorStaffService();

  Map<String, dynamic>? _technician;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTechnicianData();
  }

  Future<void> _loadTechnicianData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supervisorStaffService.getTechnicianDetail(
        widget.technicianId,
      );
      if (mounted) {
        setState(() {
          _technician = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  void _deleteTechnician() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Teknisi?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus data teknisi "${_technician?['name']}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final success = await _supervisorStaffService.deleteTechnician(
                widget.technicianId,
              );

              if (!context.mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teknisi berhasil dihapus'),
                    backgroundColor: Colors.red,
                  ),
                );
                context.pop(true); // Return to list and refresh
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus teknisi'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Use local variable for type promotion/null safety
    final technician = _technician;

    if (technician == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Detail Aktivitas'),
          backgroundColor: Colors.white,
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const Gap(16),
              Text(
                'Data teknisi tidak ditemukan',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const Gap(16),
              ElevatedButton(
                onPressed: _loadTechnicianData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
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
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil, color: Colors.blue),
            onPressed: () async {
              final result = await context.push(
                '/supervisor/technicians/edit/${widget.technicianId}',
              );
              if (result == true) {
                _loadTechnicianData(); // Refresh data
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onPressed: _deleteTechnician,
          ),
          const Gap(8),
        ],
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Safe to use ! or cast here since we checked null

            // Profile Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.supervisorColor.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      technician['name'].substring(0, 1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.supervisorColor,
                      ),
                    ),
                  ),
                  const Gap(16),
                  Text(
                    technician['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    technician['role'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const Gap(24),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        'Selesai',
                        technician['stats']['completed'].toString(),
                      ),
                      _buildVerticalDivider(),
                      _buildStatItem(
                        'Proses',
                        technician['stats']['inProgress'].toString(),
                      ),
                      _buildVerticalDivider(),
                      _buildStatItem(
                        'Avg. Waktu',
                        technician['stats']['avgTime'],
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
                  ...(technician['logs'] as List).map(
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
        bgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'process':
        iconColor = Colors.orange;
        icon = LucideIcons.wrench;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'check_in':
        iconColor = AppTheme.primaryColor;
        icon = LucideIcons.logIn;
        bgColor = AppTheme.primaryColor.withValues(alpha: 0.1);
        break;
      default:
        iconColor = Colors.grey;
        icon = LucideIcons.info;
        bgColor = Colors.grey.withValues(alpha: 0.1);
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
