import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/auth_provider.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/teknisi/presentation/widgets/teknisi_report_list_body.dart';

class TeknisiHistoryPage extends ConsumerWidget {
  const TeknisiHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

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
      body: userAsync.when(
        data: (user) => TeknisiReportListBody(
          status: 'selesai,approved',
          assignedTo: user != null ? int.tryParse(user['id'].toString()) : null,
          onReportTap: (reportId, status) {
            context.push('/teknisi/report/$reportId');
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
