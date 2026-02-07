import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/teknisi/presentation/providers/teknisi_reports_provider.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';

class TeknisiReportListBody extends ConsumerStatefulWidget {
  final String status;
  final Function(String reportId, ReportStatus status) onReportTap;
  final Color? themeColor;

  const TeknisiReportListBody({
    super.key,
    required this.status,
    required this.onReportTap,
    this.themeColor,
  });

  @override
  ConsumerState<TeknisiReportListBody> createState() =>
      _TeknisiReportListBodyState();
}

class _TeknisiReportListBodyState extends ConsumerState<TeknisiReportListBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(teknisiReportsProvider(widget.status).notifier).loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teknisiReportsProvider(widget.status));

    if (state.isLoading && state.reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!),
            const Gap(16),
            ElevatedButton(
              onPressed: () => ref
                  .read(teknisiReportsProvider(widget.status).notifier)
                  .refresh(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX, size: 64, color: Colors.grey.shade300),
            const Gap(16),
            const Text(
              'Tidak ada laporan',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(teknisiReportsProvider(widget.status).notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.reports.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.reports.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final report = state.reports[index];
          return UniversalReportCard(
            id: report.id,
            title: report.title,
            location: report.location,
            locationDetail: report.locationDetail,
            category: report.category,
            status: report.status,
            isEmergency: report.isEmergency,
            reporterName: report.reporterName,
            handledBy: report.handledBy?.join(', '),
            elapsedTime: DateTime.now().difference(report.createdAt),
            showStatus: true,
            showTimer: true,
            onTap: () => widget.onReportTap(report.id, report.status),
          );
        },
      ),
    );
  }
}
