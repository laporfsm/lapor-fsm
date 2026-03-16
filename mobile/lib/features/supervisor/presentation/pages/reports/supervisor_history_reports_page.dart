import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/presentation/widgets/supervisor_report_list_body.dart';
import 'package:go_router/go_router.dart';

class SupervisorHistoryReportsPage extends StatelessWidget {
  const SupervisorHistoryReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1454165833772-d99628a5ffef?auto=format&fit=crop&q=80&w=1000',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: AppTheme.supervisorColor),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.supervisorColor.withValues(alpha: 0.4),
                      AppTheme.supervisorColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SupervisorReportListBody(
        status: 'approved,ditolak',
        showSearch: true,
        statusFilterOptions: const [
          {'label': 'Semua', 'value': 'approved,ditolak'},
          {'label': 'Approved', 'value': 'approved'},
          {'label': 'Ditolak', 'value': 'ditolak'},
        ],
        onReportTap: (reportId, status) =>
            context.push('/supervisor/review/$reportId'),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/supervisor/export'),
          backgroundColor: Colors.white,
          child: const Icon(LucideIcons.download, color: Colors.green),
        ),
      ),
    );
  }
}
