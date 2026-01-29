import 'package:flutter/material.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/core/data/mock_report_data.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  Report? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_report == null) return const Scaffold(body: Center(child: Text('Laporan tidak ditemukan')));

    return ReportDetailBase(report: _report!, viewerRole: UserRole.pelapor);
  }
}
