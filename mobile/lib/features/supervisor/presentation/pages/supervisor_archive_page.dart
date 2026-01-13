import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class SupervisorArchivePage extends StatefulWidget {
  const SupervisorArchivePage({super.key});

  @override
  State<SupervisorArchivePage> createState() => _SupervisorArchivePageState();
}

class _SupervisorArchivePageState extends State<SupervisorArchivePage> {
  DateTimeRange? _dateRange;

  // Mock data
  final List<Map<String, dynamic>> _archives = [
    {
      'id': 1,
      'title': 'AC Mati di Lab Komputer',
      'category': 'Kelistrikan',
      'building': 'Gedung G',
      'teknisi': 'Budi Teknisi',
      'duration': '45 menit',
      'completedAt': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': 2,
      'title': 'Kebocoran Pipa Toilet',
      'category': 'Sanitasi / Air',
      'building': 'Gedung C',
      'teknisi': 'Andi Teknisi',
      'duration': '1 jam 20 menit',
      'completedAt': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': 3,
      'title': 'Lampu Koridor Mati',
      'category': 'Kelistrikan',
      'building': 'Gedung A',
      'teknisi': 'Citra Teknisi',
      'duration': '30 menit',
      'completedAt': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'id': 4,
      'title': 'Kerusakan Pintu Kelas',
      'category': 'Sipil & Bangunan',
      'building': 'Gedung B',
      'teknisi': 'Budi Teknisi',
      'duration': '2 jam',
      'completedAt': DateTime.now().subtract(const Duration(days: 5)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Arsip Laporan'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        actions: [
          IconButton(
            onPressed: _showExportDialog,
            icon: const Icon(LucideIcons.download),
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Range Picker
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: GestureDetector(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar, color: Colors.grey.shade600),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        _dateRange != null
                            ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                            : 'Pilih rentang tanggal',
                        style: TextStyle(
                          color: _dateRange != null
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (_dateRange != null)
                      GestureDetector(
                        onTap: () => setState(() => _dateRange = null),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Summary Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildSummaryItem('Total', '${_archives.length}', Colors.blue),
                _buildSummaryItem('Minggu Ini', '2', Colors.green),
                _buildSummaryItem('Bulan Ini', '4', Colors.orange),
              ],
            ),
          ),
          const Divider(height: 1),

          // Archive List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _archives.length,
              itemBuilder: (context, index) {
                return _buildArchiveCard(_archives[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveCard(Map<String, dynamic> archive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.checkCircle2,
                      size: 12,
                      color: Colors.green,
                    ),
                    Gap(4),
                    Text(
                      'Selesai',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  archive['category'],
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(archive['completedAt']),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const Gap(10),
          Text(
            archive['title'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const Gap(8),
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 14, color: Colors.grey.shade500),
              const Gap(4),
              Text(
                archive['building'],
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const Gap(16),
              Icon(LucideIcons.user, size: 14, color: Colors.grey.shade500),
              const Gap(4),
              Text(
                archive['teknisi'],
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const Gap(16),
              Icon(LucideIcons.timer, size: 14, color: Colors.grey.shade500),
              const Gap(4),
              Text(
                archive['duration'],
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(20),
            const Text(
              'Export Laporan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(20),
            Row(
              children: [
                Expanded(
                  child: _buildExportOption(
                    icon: LucideIcons.fileSpreadsheet,
                    label: 'Excel',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _exportData('excel');
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _buildExportOption(
                    icon: LucideIcons.fileText,
                    label: 'PDF',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _exportData('pdf');
                    },
                  ),
                ),
              ],
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const Gap(8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData(String format) {
    // TODO: Implement actual export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mengexport ke format $format...'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
