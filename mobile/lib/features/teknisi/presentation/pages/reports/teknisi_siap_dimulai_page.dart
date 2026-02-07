import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/teknisi/presentation/widgets/teknisi_report_list_body.dart';

class TeknisiSiapDimulaiPage extends StatelessWidget {
  const TeknisiSiapDimulaiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Siap Dimulai',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.teknisiColor,
        foregroundColor: Colors.white,
      ),
      body: TeknisiReportListBody(
        status: 'diproses,recalled',
        onReportTap: (reportId, status) {
          context.push('/teknisi/report/$reportId');
        },
      ),
    );
  }
}
