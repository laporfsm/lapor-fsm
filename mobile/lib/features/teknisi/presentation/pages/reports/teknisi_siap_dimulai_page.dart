import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/presentation/pages/shared_all_reports_page.dart';

/// Page showing all "Siap Dimulai" reports (Diproses + Recalled) assigned to the technician
class TeknisiSiapDimulaiPage extends StatefulWidget {
  const TeknisiSiapDimulaiPage({super.key});

  @override
  State<TeknisiSiapDimulaiPage> createState() => _TeknisiSiapDimulaiPageState();
}

class _TeknisiSiapDimulaiPageState extends State<TeknisiSiapDimulaiPage> {
  int? _assignedTo;

  @override
  void initState() {
    super.initState();
    _loadStaffId();
  }

  Future<void> _loadStaffId() async {
    final user = await authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _assignedTo = int.tryParse(user['id'].toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_assignedTo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SharedAllReportsPage(
      appBarTitle: 'Siap Dimulai',
      appBarColor: AppTheme.teknisiColor,
      appBarIconColor: Colors.white,
      appBarTitleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      initialStatuses: const [ReportStatus.diproses, ReportStatus.recalled],
      assignedTo: _assignedTo,
      role: 'technician',
      showBackButton: true,
      onReportTap: (reportId, status) {
        context.push('/teknisi/report/$reportId');
      },
    );
  }
}
