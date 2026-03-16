import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/presentation/widgets/supervisor_report_list_body.dart';
import 'package:go_router/go_router.dart';

class SupervisorActiveReportsPage extends StatelessWidget {
  const SupervisorActiveReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Aktif'),
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
                'https://images.unsplash.com/photo-1581094794329-cd675335442b?auto=format&fit=crop&q=80&w=1000',
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
        status: 'pending,terverifikasi,verifikasi,diproses,penanganan,onHold,selesai,recalled',
        showSearch: true,
        statusFilterOptions: const [
          {'label': 'Semua', 'value': 'pending,terverifikasi,verifikasi,diproses,penanganan,onHold,selesai,recalled'},
          {'label': 'Pending', 'value': 'pending'},
          {'label': 'Terverifikasi', 'value': 'terverifikasi'},
          {'label': 'Diproses', 'value': 'diproses'},
          {'label': 'Penanganan', 'value': 'penanganan'},
          {'label': 'On Hold', 'value': 'onHold'},
          {'label': 'Selesai', 'value': 'selesai'},
          {'label': 'Recalled', 'value': 'recalled'},
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
