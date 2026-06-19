import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/presentation/widgets/supervisor_report_list_body.dart';
import 'package:mobile/features/supervisor/presentation/providers/supervisor_reports_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';

class SupervisorActiveReportsPage extends ConsumerStatefulWidget {
  const SupervisorActiveReportsPage({super.key});

  @override
  ConsumerState<SupervisorActiveReportsPage> createState() =>
      _SupervisorActiveReportsPageState();
}

class _SupervisorActiveReportsPageState
    extends ConsumerState<SupervisorActiveReportsPage> {
  static const String _status =
      'pending,terverifikasi,verifikasi,diproses,penanganan,onHold,selesai,recalled';

  Future<void> _mergeReports(List<String> selectedIds) async {
    final notesController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gabungkan Laporan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan menggabungkan ${selectedIds.length} laporan menjadi satu group.',
              style: const TextStyle(fontSize: 14),
            ),
            const Gap(16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Penggabungan',
                hintText: 'Opsional',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              const Gap(8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.supervisorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('Gabungkan'),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final authService = AuthService();
        final user = await authService.getCurrentUser();
        final staffId = int.tryParse(user?['id']?.toString() ?? '0') ?? 0;

        await reportService.groupReports(
          selectedIds,
          staffId,
          notes: notesController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan berhasil digabungkan')),
          );
          ref
              .read(supervisorReportsProvider(_status).notifier)
              .exitSelectionMode();
          ref.read(supervisorReportsProvider(_status).notifier).refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(supervisorReportsProvider(_status));
    final notifier = ref.read(supervisorReportsProvider(_status).notifier);

    return Scaffold(
      appBar: reportState.isSelectionMode
          ? AppBar(
              title: Text(
                '${reportState.selectedReportIds.length} Terpilih',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppTheme.supervisorColor,
              leading: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white),
                onPressed: () => notifier.exitSelectionMode(),
              ),
            )
          : AppBar(
              title: const Text('Laporan Aktif'),
              centerTitle: true,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1581094794329-cd675335442b?auto=format&fit=crop&q=80&w=1000',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: AppTheme.supervisorColor),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.supervisorColor.withValues(alpha: 0.4),
                            AppTheme.supervisorColor.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: SupervisorReportListBody(
        status: _status,
        showSearch: true,
        statusFilterOptions: const [
          {'label': 'Semua', 'value': _status},
          {'label': 'Pending', 'value': 'pending'},
          {'label': 'Terverifikasi', 'value': 'terverifikasi'},
          {'label': 'Diproses', 'value': 'diproses'},
          {'label': 'Penanganan', 'value': 'penanganan'},
          {'label': 'On Hold', 'value': 'onHold'},
          {'label': 'Selesai', 'value': 'selesai'},
          {'label': 'Recalled', 'value': 'recalled'},
        ],
        onReportTap: (reportId, status) async {
          await context.push('/supervisor/review/$reportId');
          ref.read(supervisorReportsProvider(_status).notifier).refresh();
        },
        onMerge: (selectedIds) => _mergeReports(selectedIds),
        floatingActionButton: reportState.isSelectionMode
            ? null // Hide FAB in selection mode, use bottom bar instead
            : FloatingActionButton(
                onPressed: () => context.push('/supervisor/export'),
                backgroundColor: Colors.white,
                child: const Icon(LucideIcons.download, color: Colors.green),
              ),
      ),
    );
  }
}
