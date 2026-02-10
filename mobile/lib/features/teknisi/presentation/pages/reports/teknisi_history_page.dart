import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/teknisi/presentation/widgets/teknisi_report_list_body.dart';

class TeknisiHistoryPage extends StatelessWidget {
  const TeknisiHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Laporan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.teknisiColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Root tab
      ),
      body: TeknisiReportListBody(
        status: 'selesai,approved',
        onReportTap: (reportId, status) {
          context.push('/teknisi/report/$reportId');
        },
      ),
    );
  }
}
