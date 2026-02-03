import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:gap/gap.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/domain/entities/report_log.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';
import 'package:mobile/features/report_common/domain/enums/user_role.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';

class SupervisorReviewPage extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic>? extra;

  const SupervisorReviewPage({super.key, required this.reportId, this.extra});

  @override
  State<SupervisorReviewPage> createState() => _SupervisorReviewPageState();
}

class _SupervisorReviewPageState extends State<SupervisorReviewPage> {
  Report? _report;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final data = await reportService.getReportDetail(widget.reportId);
      if (data != null && mounted) {
        setState(() {
          _report = Report.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_report == null) {
      return const Scaffold(
        body: Center(child: Text('Laporan tidak ditemukan')),
      );
    }

    return ReportDetailBase(
      report: _report!,
      viewerRole: UserRole.supervisor,
      appBarColor: AppTheme.supervisorColor,
      actionButtons: _buildActionButtons(),
    );
  }

  List<Widget> _buildActionButtons() {
    final r = _report;
    if (r == null) return [];

    switch (r.status) {
      case ReportStatus.pending:
        // Menunggu Verifikasi
        return [
          OutlinedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _updateReportStatus(
                    ReportStatus.ditolak,
                    ReportAction.rejected,
                  ),
            icon: const Icon(LucideIcons.xCircle),
            label: const Text('Tolak'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _updateReportStatus(
                    ReportStatus.verifikasi,
                    ReportAction.verified,
                  ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.checkCircle),
            label: _isProcessing
                ? const Text('Proses...')
                : const Text('Verifikasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.supervisorColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ];

      case ReportStatus.verifikasi: // Legacy / Verifikasi PJ
      case ReportStatus.terverifikasi: // Siap Assign
        // Siap diproses -> Tugaskan Teknisi
        return [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _showAssignTechnicianDialog,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.userPlus),
            label: _isProcessing
                ? const Text('Proses...')
                : const Text('Tugaskan Teknisi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.supervisorColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ];

      case ReportStatus.selesai:
        // Menunggu Approval
        return [
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _showRecallDialog,
            icon: const Icon(LucideIcons.rotateCcw),
            label: const Text('Recall (Revisi)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _updateReportStatus(
                    ReportStatus.approved,
                    ReportAction.approved,
                  ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.checkCircle),
            label: _isProcessing
                ? const Text('Proses...')
                : const Text('Setujui'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ];

      default:
        // No actions for other statuses
        return [];
    }
  }

  void _updateReportStatus(
    ReportStatus newStatus,
    ReportAction action, {
    String? notes,
    String? technicianId,
  }) async {
    if (_report == null) return;
    setState(() => _isProcessing = true);

    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final staffId = int.parse(user['id'].toString());

        switch (action) {
          case ReportAction.verified:
            await reportService.verifyReport(
              _report!.id,
              staffId,
              role: 'supervisor',
            );
            break;
          case ReportAction.handling:
            if (technicianId != null) {
              await reportService.assignTechnician(
                _report!.id,
                staffId,
                int.parse(technicianId),
              );
            }
            break;
          case ReportAction.recalled:
            await reportService.recallReport(_report!.id, staffId, notes ?? '');
            break;
          case ReportAction.approved:
            await reportService.approveResult(
              _report!.id,
              staffId,
              notes: notes,
            );
            break;
          case ReportAction.rejected:
            await reportService.rejectReport(
              _report!.id,
              staffId,
              notes ?? 'Ditolak oleh Supervisor',
            );
            break;
          default:
            break;
        }

        if (!mounted) return;
        await _loadReport();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status laporan berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        if (newStatus == ReportStatus.ditolak ||
            newStatus == ReportStatus.approved) {
          context.pop();
        }
      }
    } catch (e) {
      debugPrint('Error updating report status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showAssignTechnicianDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AssignTechnicianSheet(
        onAssign: (technicianId) {
          Navigator.pop(context);
          _updateReportStatus(
            ReportStatus.diproses,
            ReportAction.handling,
            technicianId: technicianId,
          );
        },
      ),
    );
  }

  void _showRecallDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recall Laporan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Berikan alasan atau catatan revisi untuk teknisi:'),
            const Gap(12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Foto perbaikan kurang jelas...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) return;
              _updateReportStatus(
                ReportStatus.recalled,
                ReportAction.recalled,
                notes: reasonController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Recall'),
          ),
        ],
      ),
    );
  }
}

class _AssignTechnicianSheet extends StatefulWidget {
  final Function(String) onAssign;

  const _AssignTechnicianSheet({required this.onAssign});

  @override
  State<_AssignTechnicianSheet> createState() => _AssignTechnicianSheetState();
}

class _AssignTechnicianSheetState extends State<_AssignTechnicianSheet> {
  String? _selectedTechnicianId;
  List<dynamic> _technicians = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  Future<void> _fetchTechnicians() async {
    try {
      final techs = await reportService.getTechnicians();
      if (mounted) {
        setState(() {
          _technicians = techs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tugaskan Teknisi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _technicians.isEmpty
                ? const Center(child: Text('Tidak ada teknisi tersedia'))
                : ListView.separated(
                    itemCount: _technicians.length,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) {
                      final tech = _technicians[index];
                      final techId = tech['id'].toString();
                      final isSelected = _selectedTechnicianId == techId;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTechnicianId = techId;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.supervisorColor.withValues(
                                    alpha: 0.05,
                                  )
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.supervisorColor
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.supervisorColor
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  tech['name'][0],
                                  style: TextStyle(
                                    color: AppTheme.supervisorColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tech['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      tech['specialization'] ?? 'Umum',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  LucideIcons.checkCircle2,
                                  color: AppTheme.supervisorColor,
                                )
                              else
                                Icon(
                                  LucideIcons.circle,
                                  color: Colors.grey.shade300,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedTechnicianId != null
                  ? () => widget.onAssign(_selectedTechnicianId!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.supervisorColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Simpan Penugasan'),
            ),
          ),
        ],
      ),
    );
  }
}
