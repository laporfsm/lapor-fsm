import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/report_detail_wrapper.dart';
import 'package:mobile/features/report_common/domain/enums/user_role.dart';

class ReportDetailPage extends StatelessWidget {
  final String reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return ReportDetailWrapper(
      reportId: reportId,
      viewerRole: UserRole.pelapor,
    );
  }
}
