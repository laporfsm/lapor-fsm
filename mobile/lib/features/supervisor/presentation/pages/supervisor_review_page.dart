import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:gap/gap.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/models/report_log.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/core/data/mock_report_data.dart';

class SupervisorReviewPage extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic>? extra;

  const SupervisorReviewPage({super.key, required this.reportId, this.extra});

  @override
  State<SupervisorReviewPage> createState() => _SupervisorReviewPageState();
}

class _SupervisorReviewPageState extends State<SupervisorReviewPage> {
  late Report _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          // Use MockReportData instead of hardcoded report
          _report = MockReportData.getReportOrDefault(widget.reportId);
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

    return ReportDetailBase(
      report: _report,
      viewerRole: UserRole.supervisor,
      appBarColor: AppTheme.supervisorColor,
      actionButtons: _buildActionButtons(),
    );
  }

  List<Widget> _buildActionButtons() {
    switch (_report.status) {
      case ReportStatus.pending:
        // Menunggu Verifikasi
        return [
          OutlinedButton.icon(
            onPressed: () => _updateReportStatus(
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
            onPressed: () => _updateReportStatus(
              ReportStatus.verifikasi,
              ReportAction.verified,
            ),
            icon: const Icon(LucideIcons.checkCircle),
            label: const Text('Verifikasi'),
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
            onPressed: _showAssignTechnicianDialog,
            icon: const Icon(LucideIcons.userPlus),
            label: const Text('Tugaskan Teknisi'),
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
            onPressed: _showRecallDialog,
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
            onPressed: () => _updateReportStatus(
              ReportStatus.approved,
              ReportAction.approved,
            ),
            icon: const Icon(LucideIcons.checkCircle),
            label: const Text('Setujui'),
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
    List<String>? handledBy,
  }) {
    setState(() {
      final newLog = ReportLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        fromStatus: _report.status,
        toStatus: newStatus,
        action: action,
        actorId: 'spv1',
        actorName: 'Supervisor',
        actorRole: 'Supervisor',
        timestamp: DateTime.now(),
        reason: notes,
      );

      _report = _report.copyWith(
        status: newStatus,
        handledBy: handledBy,
        logs: [newLog, ..._report.logs],
        supervisorName: 'Supervisor',
        verifiedAt:
            (newStatus == ReportStatus.terverifikasi ||
                newStatus == ReportStatus.verifikasi)
            ? DateTime.now()
            : null,
      );
    });

    String message = 'Status laporan berhasil diperbarui';
    if (newStatus == ReportStatus.approved) message = 'Laporan disetujui';
    if (newStatus == ReportStatus.ditolak) message = 'Laporan ditolak';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );

    context.pop();
  }

  void _showAssignTechnicianDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AssignTechnicianSheet(
        onAssign: (technicians) {
          _updateReportStatus(
            ReportStatus.diproses,
            ReportAction.handling,
            notes: 'Ditugaskan ke ${technicians.join(", ")}',
            handledBy: technicians,
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
  final Function(List<String>) onAssign;

  const _AssignTechnicianSheet({required this.onAssign});

  @override
  State<_AssignTechnicianSheet> createState() => _AssignTechnicianSheetState();
}

class _AssignTechnicianSheetState extends State<_AssignTechnicianSheet> {
  final List<String> _selectedTechnicians = [];

  // Mock data with status
  final List<Map<String, dynamic>> _technicians = [
    {
      'name': 'Budi Teknisi',
      'role': 'Kelistrikan',
      'lastActivity': 'Menangani AC Lab (5m lalu)',
      'isAvailable': false,
    },
    {
      'name': 'Andi Teknisi',
      'role': 'Sipil',
      'lastActivity': 'Selesai Pipa Toilet (30m lalu)',
      'isAvailable': true,
    },
    {
      'name': 'Citra Teknisi',
      'role': 'K3',
      'lastActivity': 'Inspeksi Rutin (1j lalu)',
      'isAvailable': true,
    },
    {
      'name': 'Eko Teknisi',
      'role': 'Umum',
      'lastActivity': 'Istirahat',
      'isAvailable': true,
    },
  ];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tugaskan Teknisi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_selectedTechnicians.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.supervisorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedTechnicians.length} Dipilih',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const Gap(16),
          Expanded(
            child: ListView.separated(
              itemCount: _technicians.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final tech = _technicians[index];
                final isSelected = _selectedTechnicians.contains(tech['name']);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTechnicians.remove(tech['name']);
                      } else {
                        _selectedTechnicians.add(tech['name']);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.supervisorColor.withOpacity(0.05)
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
                        // Avatar
                        CircleAvatar(
                          backgroundColor: AppTheme.supervisorColor.withOpacity(
                            0.1,
                          ),
                          child: Text(
                            (tech['name'] as String)[0],
                            style: TextStyle(
                              color: AppTheme.supervisorColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Gap(12),
                        // Info
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
                                tech['role'],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const Gap(4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.activity,
                                      size: 10,
                                      color: Colors.grey,
                                    ),
                                    const Gap(4),
                                    Text(
                                      tech['lastActivity'],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Checkbox (custom for visuals)
                        if (isSelected)
                          const Icon(
                            LucideIcons.checkCircle2,
                            color: AppTheme.supervisorColor,
                          )
                        else
                          Icon(LucideIcons.circle, color: Colors.grey.shade300),
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
              onPressed: _selectedTechnicians.isNotEmpty
                  ? () => widget.onAssign(_selectedTechnicians)
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
