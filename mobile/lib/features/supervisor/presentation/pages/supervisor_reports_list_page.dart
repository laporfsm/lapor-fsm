import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class SupervisorReportsListPage extends StatefulWidget {
  final String? initialStatus;
  final String? initialPeriod;
  final bool showEmergencyOnly;

  const SupervisorReportsListPage({
    super.key,
    this.initialStatus,
    this.initialPeriod,
    this.showEmergencyOnly = false,
  });

  @override
  State<SupervisorReportsListPage> createState() =>
      _SupervisorReportsListPageState();
}

class _SupervisorReportsListPageState extends State<SupervisorReportsListPage> {
  // Mock data
  final List<Map<String, dynamic>> _allReports = [
    {
      'id': 1,
      'title': 'AC Mati di Lab Komputer',
      'location': 'Gedung G, Lt 2, Ruang 201',
      'status': 'pending',
      'date': DateTime.now(),
      'isEmergency': false,
      'reporter': 'Ahmad Fauzi',
    },
    {
      'id': 2,
      'title': 'Kebocoran Pipa Toilet',
      'location': 'Gedung C, Lt 1, Toilet Pria',
      'status': 'verifikasi',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'isEmergency': false,
      'reporter': 'Siti Aminah',
    },
    {
      'id': 3,
      'title': 'Kecelakaan di Lab Kimia',
      'location': 'Gedung D, Lt 3',
      'status': 'penanganan',
      'date': DateTime.now().subtract(const Duration(hours: 5)),
      'isEmergency': true,
      'reporter': 'Budi Santoso',
    },
    {
      'id': 4,
      'title': 'Lampu Koridor Mati',
      'location': 'Gedung A, Lt 1',
      'status': 'selesai',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'isEmergency': false,
      'reporter': 'Dewi Lestari',
    },
    {
      'id': 5,
      'title': 'Kebakaran Kecil di Kantin',
      'location': 'Kantin Utama',
      'status': 'pending',
      'date': DateTime.now().subtract(const Duration(minutes: 10)),
      'isEmergency': true,
      'reporter': 'Rudi Hartono',
    },
  ];

  late String _selectedStatus;
  late bool _showEmergencyOnly;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? 'all';
    _showEmergencyOnly = widget.showEmergencyOnly;
  }

  List<Map<String, dynamic>> get _filteredReports {
    return _allReports.where((report) {
      // Filter by emergency
      if (_showEmergencyOnly && report['isEmergency'] != true) {
        return false;
      }

      // Filter by status
      if (_selectedStatus != 'all' && report['status'] != _selectedStatus) {
        return false;
      }

      // Filter by period (mock implementation)
      if (widget.initialPeriod != null) {
        final date = report['date'] as DateTime;
        final now = DateTime.now();
        if (widget.initialPeriod == 'today') {
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }
        // Add more period filters if needed
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = _showEmergencyOnly
        ? 'Laporan Darurat'
        : widget.initialPeriod != null
        ? 'Laporan ${widget.initialPeriod == 'today'
              ? 'Hari Ini'
              : widget.initialPeriod == 'week'
              ? 'Minggu Ini'
              : 'Bulan Ini'}'
        : 'Daftar Laporan';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _showEmergencyOnly ? Colors.red : Colors.white,
        foregroundColor: _showEmergencyOnly ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips (Only show if not in emergency mode)
          if (!_showEmergencyOnly)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('Semua', 'all'),
                  const Gap(8),
                  _buildFilterChip('Pending', 'pending'),
                  const Gap(8),
                  _buildFilterChip('Verifikasi', 'verifikasi'),
                  const Gap(8),
                  _buildFilterChip('Penanganan', 'penanganan'),
                  const Gap(8),
                  _buildFilterChip('Selesai', 'selesai'),
                ],
              ),
            ),

          Expanded(
            child: _filteredReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.fileX,
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
                      final report = _filteredReports[index];
                      return _buildReportCard(report);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = status);
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    // Determine status color and text
    final status = report['status'].toString().toLowerCase();
    Color statusColor;

    switch (status) {
      case 'pending':
        statusColor = Colors.grey;
        break;
      case 'verifikasi':
        statusColor = Colors.blue;
        break;
      case 'penanganan':
        statusColor = AppTheme.secondaryColor;
        break;
      case 'selesai':
        statusColor = Colors.green;
        break;
      case 'ditolak':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    final isEmergency = report['isEmergency'] == true;

    return GestureDetector(
      onTap: () {
        context.push('/supervisor/review/${report['id']}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isEmergency ? Border.all(color: Colors.red, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID/Date & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isEmergency)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.alertTriangle,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const Gap(4),
                                Text(
                                  'DARURAT',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          '#${report['id']} • ${DateFormat('dd MMM yyyy, HH:mm').format(report['date'])}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      report['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(10),

              // Title
              Text(
                report['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Gap(8),

              // Location
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const Gap(6),
                  Expanded(
                    child: Text(
                      report['location'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const Gap(6),

              // Reporter info
              Row(
                children: [
                  Icon(LucideIcons.user, size: 14, color: Colors.grey.shade500),
                  const Gap(6),
                  Text(
                    report['reporter'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),

              // Action Button
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/supervisor/review/${report['id']}');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Lihat Detail',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
