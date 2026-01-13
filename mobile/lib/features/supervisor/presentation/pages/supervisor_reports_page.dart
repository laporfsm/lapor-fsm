import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class SupervisorReportsPage extends StatefulWidget {
  const SupervisorReportsPage({super.key});

  @override
  State<SupervisorReportsPage> createState() => _SupervisorReportsPageState();
}

class _SupervisorReportsPageState extends State<SupervisorReportsPage> {
  String _selectedStatus = 'all';
  final List<String> _statuses = [
    'all',
    'pending',
    'verifikasi',
    'penanganan',
    'selesai',
  ];

  // Mock data
  final List<Map<String, dynamic>> _reports = [
    {
      'id': 1,
      'title': 'AC Mati di Lab Komputer',
      'category': 'Kelistrikan',
      'building': 'Gedung G, Lt 2',
      'status': 'selesai',
      'teknisi': 'Budi Teknisi',
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      'duration': '45 menit',
      'isEmergency': false,
    },
    {
      'id': 2,
      'title': 'Kebocoran Pipa Toilet',
      'category': 'Sanitasi / Air',
      'building': 'Gedung C, Lt 1',
      'status': 'penanganan',
      'teknisi': 'Andi Teknisi',
      'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
      'duration': null,
      'isEmergency': false,
    },
    {
      'id': 3,
      'title': 'Kecelakaan di Lab Kimia',
      'category': 'K3 Lab',
      'building': 'Gedung D, Lt 3',
      'status': 'penanganan',
      'teknisi': 'Citra Teknisi',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
      'duration': null,
      'isEmergency': true,
    },
    {
      'id': 4,
      'title': 'Lampu Koridor Mati',
      'category': 'Kelistrikan',
      'building': 'Gedung A, Lt 1',
      'status': 'pending',
      'teknisi': null,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 15)),
      'duration': null,
      'isEmergency': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredReports {
    if (_selectedStatus == 'all') return _reports;
    return _reports.where((r) => r['status'] == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Semua Laporan'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(LucideIcons.filter),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((status) {
                  final isSelected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getStatusLabel(status)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedStatus = status);
                      },
                      selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF6366F1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Reports List
          Expanded(
            child: _filteredReports.isEmpty
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
                        Text(
                          'Tidak ada laporan',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      return _buildReportCard(_filteredReports[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final statusColor = _getStatusColor(report['status']);
    final bool isEmergency = report['isEmergency'] ?? false;

    return GestureDetector(
      onTap: () => context.push('/supervisor/review/${report['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isEmergency
              ? Border.all(color: AppTheme.emergencyColor, width: 2)
              : null,
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
            if (isEmergency)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: AppTheme.emergencyColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: const Center(
                  child: Text(
                    '⚠️ DARURAT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusLabel(report['status']),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          report['category'],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(report['createdAt']),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Text(
                    report['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const Gap(4),
                      Expanded(
                        child: Text(
                          report['building'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (report['teknisi'] != null) ...[
                    const Gap(6),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.user,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const Gap(4),
                        Text(
                          report['teknisi'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        if (report['duration'] != null) ...[
                          const Gap(12),
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
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'all':
        return 'Semua';
      case 'pending':
        return 'Pending';
      case 'verifikasi':
        return 'Verifikasi';
      case 'penanganan':
        return 'Penanganan';
      case 'penanganan_ulang':
        return 'Penanganan Ulang';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'verifikasi':
        return Colors.blue;
      case 'penanganan':
        return Colors.orange;
      case 'penanganan_ulang':
        return Colors.deepOrange;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Laporan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            const Text('Filter by date, category, and building coming soon...'),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
