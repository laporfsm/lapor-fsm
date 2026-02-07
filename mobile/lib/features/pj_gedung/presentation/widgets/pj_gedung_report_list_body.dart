import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/pj_gedung/presentation/providers/pj_gedung_reports_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';

class PjGedungReportListBody extends ConsumerStatefulWidget {
  final String status;
  final Function(String reportId, ReportStatus status) onReportTap;
  final bool showSearch;
  final String? category;
  final String? location;
  final bool? isEmergency;
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;
  final Widget? floatingActionButton;

  const PjGedungReportListBody({
    super.key,
    required this.status,
    required this.onReportTap,
    this.showSearch = false,
    this.category,
    this.location,
    this.isEmergency,
    this.period,
    this.startDate,
    this.endDate,
    this.floatingActionButton,
  });

  @override
  ConsumerState<PjGedungReportListBody> createState() =>
      _PjGedungReportListBodyState();
}

class _PjGedungReportListBodyState
    extends ConsumerState<PjGedungReportListBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(pjGedungReportsProvider(widget.status).notifier)
          .setFilters(
            category: widget.category,
            location: widget.location,
            isEmergency: widget.isEmergency,
            period: widget.period,
            startDate: widget.startDate,
            endDate: widget.endDate,
          );
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PjGedungReportListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.category != oldWidget.category ||
        widget.location != oldWidget.location ||
        widget.isEmergency != oldWidget.isEmergency ||
        widget.period != oldWidget.period ||
        widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(pjGedungReportsProvider(widget.status).notifier)
            .setFilters(
              category: widget.category,
              location: widget.location,
              isEmergency: widget.isEmergency,
              period: widget.period,
              startDate: widget.startDate,
              endDate: widget.endDate,
            );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = ref.read(
        pjGedungReportsProvider(widget.status).notifier,
      );
      final state = ref.read(pjGedungReportsProvider(widget.status));
      if (!state.isFetchingMore && state.hasMore) {
        provider.fetchMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pjGedungReportsProvider(widget.status));
    final notifier = ref.read(pjGedungReportsProvider(widget.status).notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          if (widget.showSearch)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                onChanged: (value) => notifier.setSearchQuery(value),
                decoration: InputDecoration(
                  hintText: 'Cari laporan...',
                  prefixIcon: const Icon(LucideIcons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await notifier.fetchReports(isRefresh: true);
              },
              child: state.isLoading && state.reports.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.reports.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.clipboardList,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const Gap(16),
                              Text(
                                'Belum ada laporan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          state.reports.length + (state.isFetchingMore ? 1 : 0),
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
                          elapsedTime: report.elapsed,
                          reporterName: report.reporterName,
                          handledBy: report.handledBy?.join(', '),
                          onTap: () {
                            widget.onReportTap(report.id, report.status);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
