import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';

// Shared Report features
import 'package:mobile/features/supervisor/presentation/widgets/supervisor_report_list_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Now functions as "Riwayat" tab view
class SupervisorArchivePage extends ConsumerStatefulWidget {
  const SupervisorArchivePage({super.key});

  @override
  ConsumerState<SupervisorArchivePage> createState() =>
      _SupervisorArchivePageState();
}

class _SupervisorArchivePageState extends ConsumerState<SupervisorArchivePage> {
  DateTimeRange? _dateRange;

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
              ],
            ),
          ),

          const Divider(height: 1),

          // Archive List
          Expanded(
            child: SupervisorReportListBody(
              status: 'approved,ditolak',
              startDate: _dateRange?.start,
              endDate: _dateRange?.end,
              showSearch: true,
              onReportTap: (reportId, status) {
                context.push('/supervisor/review/$reportId');
              },
              floatingActionButton: FloatingActionButton(
                onPressed: _showExportDialog,
                backgroundColor: Colors.white,
                child: const Icon(LucideIcons.download, color: Colors.green),
              ),
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
