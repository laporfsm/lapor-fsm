import 'package:flutter/material.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/core/data/mock_report_data.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  late Report _report;

  @override
  void initState() {
    super.initState();
    _report = MockReportData.getReportOrDefault(widget.reportId);
  }

  @override
  Widget build(BuildContext context) {
    return ReportDetailBase(report: _report, viewerRole: UserRole.pelapor);
  }
}
