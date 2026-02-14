import 'package:flutter/material.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/user_role.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';

class ReportDetailWrapper extends StatefulWidget {
  final String reportId;
  final UserRole viewerRole;
  final Color? appBarColor;
  final List<Widget>? Function(Report, Future<void> Function() refresh)?
  actionButtonsBuilder;
  final Future<void> Function()? onRefresh;

  const ReportDetailWrapper({
    super.key,
    required this.reportId,
    required this.viewerRole,
    this.appBarColor,
    this.actionButtonsBuilder,
    this.onRefresh,
  });

  @override
  State<ReportDetailWrapper> createState() => _ReportDetailWrapperState();
}

class _ReportDetailWrapperState extends State<ReportDetailWrapper> {
  Report? _report;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await reportService.getReportDetail(widget.reportId);
      if (mounted) {
        if (data != null) {
          setState(() {
            _report = Report.fromJson(data);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Laporan tidak ditemukan';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan saat memuat data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null || _report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Laporan tidak ditemukan'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReport,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return ReportDetailBase(
      report: _report!,
      viewerRole: widget.viewerRole,
      appBarColor: widget.appBarColor,
      actionButtons: widget.actionButtonsBuilder?.call(_report!, _loadReport),
      onReportChanged: _loadReport,
    );
  }
}
