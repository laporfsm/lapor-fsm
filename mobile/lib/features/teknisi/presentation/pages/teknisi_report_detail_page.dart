import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/core/models/report_log.dart'; // Keep logs in core for now or check if moved
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/data/mock_report_data.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';
import 'package:mobile/theme.dart';

class TeknisiReportDetailPage extends StatefulWidget {
  final String reportId;

  const TeknisiReportDetailPage({super.key, required this.reportId});

  @override
  State<TeknisiReportDetailPage> createState() =>
      _TeknisiReportDetailPageState();
}

class _TeknisiReportDetailPageState extends State<TeknisiReportDetailPage> {
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
      return const Scaffold(body: Center(child: Text('Laporan tidak ditemukan')));
    }

    return ReportDetailBase(
      report: _report!,
      viewerRole: UserRole.teknisi,
      actionButtons: _buildActionButtons(),
    );
  }

  List<Widget> _buildActionButtons() {
    final r = _report!;
    
    // Status: diproses - Teknisi bisa mulai penanganan
    if (r.status == ReportStatus.diproses) {
      return [
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _startHandling,
          icon: _isProcessing 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(LucideIcons.play),
          label: Text(_isProcessing ? 'Memproses...' : 'Mulai Penanganan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    }
    // Status: penanganan - Teknisi bisa pause atau selesaikan
    else if (r.status == ReportStatus.penanganan) {
      return [
        // Pause Button
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : _pauseReport,
          icon: const Icon(LucideIcons.pauseCircle),
          label: const Text('Pause'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        // Selesaikan Button
        ElevatedButton.icon(
          onPressed: () =>
              context.push('/teknisi/report/${widget.reportId}/complete'),
          icon: const Icon(LucideIcons.checkCircle2),
          label: const Text('Selesaikan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    } else if (r.status == ReportStatus.onHold) {
      return [
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _resumeReport,
          icon: _isProcessing 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(LucideIcons.playCircle),
          label: Text(_isProcessing ? 'Memproses...' : 'Lanjutkan Pekerjaan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    }
    return [];
  }

  void _startHandling() async {
    setState(() => _isProcessing = true);
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final staffId = user['id'];
        final success = await reportService.acceptReport(widget.reportId, staffId);
        if (success) {
          await _loadReport();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Penanganan dimulai'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('Error accepting report: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _pauseReport() {
    showDialog(
      context: context,
      builder: (context) {
        String reason = '';
        return AlertDialog(
          title: const Text('Tunda Pengerjaan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan alasan penundaan (misal: menunggu sparepart):',
              ),
              const Gap(12),
              TextField(
                onChanged: (value) => reason = value,
                decoration: const InputDecoration(
                  hintText: 'Alasan penundaan...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              // TODO: Add Photo Upload Implementation
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isProcessing = true);
                try {
                  final user = await authService.getCurrentUser();
                  if (user != null) {
                    final staffId = user['id'];
                    final success = await reportService.pauseReport(widget.reportId, staffId, reason);
                    if (success) {
                      await _loadReport();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pengerjaan ditunda (Pause)'), backgroundColor: Colors.orange),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Error pausing report: $e');
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tunda'),
            ),
          ],
        );
      },
    );
  }

  void _resumeReport() async {
    setState(() => _isProcessing = true);
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final staffId = user['id'];
        final success = await reportService.resumeReport(widget.reportId, staffId);
        if (success) {
          await _loadReport();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengerjaan dilanjutkan'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('Error resuming report: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
