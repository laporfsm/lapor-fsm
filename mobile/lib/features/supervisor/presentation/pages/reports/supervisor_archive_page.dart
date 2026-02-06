import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';

// Shared Report features
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';

// Now functions as "Riwayat" tab view
class SupervisorArchivePage extends StatefulWidget {
  const SupervisorArchivePage({super.key});

  @override
  State<SupervisorArchivePage> createState() => _SupervisorArchivePageState();
}

class _SupervisorArchivePageState extends State<SupervisorArchivePage> {
  DateTimeRange? _dateRange;

  // Mock data - Only "Approved"
  // Note: User logic says Riwayat = Approved.
  // I will also add one 'ditolak' just in case to verify filter if I wanted to, but for now strict Approved.
  final List<Report> _archives = [
    Report(
      id: '1',
      title: 'AC Mati di Lab Komputer',
      description: 'Selesai diperbaiki',
      category: 'Kelistrikan',
      location: 'Lokasi G',
      status: ReportStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isEmergency: false,
      reporterId: 'user1',
      reporterName: 'Ahmad Fauzi',
      handledBy: ['Budi Teknisi'],
    ),
    Report(
      id: '2',
      title: 'Kebocoran Pipa Toilet',
      description: 'Pipa diganti baru',
      category: 'Sanitasi / Air',
      location: 'Lokasi C',
      status: ReportStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isEmergency: false,
      reporterId: 'user2',
      reporterName: 'Siti Aminah',
      handledBy: ['Andi Teknisi'],
    ),
    Report(
      id: '3',
      title: 'Lampu Koridor Mati',
      description: 'Bohlam diganti',
      category: 'Kelistrikan',
      location: 'Lokasi A',
      status: ReportStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isEmergency: false,
      reporterId: 'user3',
      reporterName: 'Citra Teknisi',
      handledBy: ['Citra Teknisi'],
    ),
    Report(
      id: '4',
      title: 'Kerusakan Pintu Kelas',
      description: 'Engsel diperbaiki',
      category: 'Sipil & Bangunan',
      location: 'Lokasi B',
      status: ReportStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isEmergency: false,
      reporterId: 'user4',
      reporterName: 'Budi Teknisi',
      handledBy: ['Budi Teknisi'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Return content directly (no Scaffold)
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // No AppBar, it's handled by Tab container
      body: Column(
        children: [
          // Date Range Picker & Export Actions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
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
                          Icon(
                            LucideIcons.calendar,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const Gap(12),
                          Expanded(
                            child: Text(
                              _dateRange != null
                                  ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                                  : 'Filter Tanggal',
                              style: TextStyle(
                                color: _dateRange != null
                                    ? Colors.black
                                    : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_dateRange != null)
                            GestureDetector(
                              onTap: () => setState(() => _dateRange = null),
                              child: Icon(
                                LucideIcons.x,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                IconButton(
                  onPressed: _showExportDialog,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    LucideIcons.download,
                    size: 20,
                    color: Colors.black87,
                  ),
                  tooltip: 'Export',
                ),
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
                // Determine if we need to filter by date logic here if _dateRange is set
                // For now just showing all mocks
                final report = _archives[index];
                return UniversalReportCard(
                  id: report.id,
                  title: report.title,
                  location: report.location,
                  locationDetail: report.locationDetail,
                  category: report.category,
                  status: report.status,
                  isEmergency: report.isEmergency,
                  reporterName: report.reporterName,
                  handledBy: report.handledBy?.join(', '),
                  onTap: () => context.push('/supervisor/review/${report.id}'),
                );
              },
            ),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
