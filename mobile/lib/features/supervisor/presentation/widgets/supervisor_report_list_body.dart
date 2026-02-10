import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/supervisor/presentation/providers/supervisor_reports_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';

class SupervisorReportListBody extends ConsumerStatefulWidget {
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

  const SupervisorReportListBody({
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
  ConsumerState<SupervisorReportListBody> createState() =>
      _SupervisorReportListBodyState();
}

class _SupervisorReportListBodyState
    extends ConsumerState<SupervisorReportListBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(supervisorReportsProvider(widget.status).notifier)
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

  @override
  void didUpdateWidget(covariant SupervisorReportListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.category != oldWidget.category ||
        widget.location != oldWidget.location ||
        widget.isEmergency != oldWidget.isEmergency ||
        widget.period != oldWidget.period ||
        widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(supervisorReportsProvider(widget.status).notifier)
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = ref.read(
        supervisorReportsProvider(widget.status).notifier,
      );
      final state = ref.read(supervisorReportsProvider(widget.status));
      if (!state.isLoadingMore && state.hasMore) {
        provider.loadReports();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supervisorReportsProvider(widget.status));
    final notifier = ref.read(
      supervisorReportsProvider(widget.status).notifier,
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          _onScroll();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Column(
          children: [
            if (widget.showSearch)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  onChanged: (value) => notifier.setSearch(value),
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
                  await notifier.refresh();
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
                            state.reports.length +
                            (state.isLoadingMore ? 1 : 0),
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
                          final isSelected = state.selectedReportIds.contains(
                            report.id,
                          );

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
                            selectionMode: state.isSelectionMode,
                            isSelected: isSelected,
                            onTap: () {
                              if (state.isSelectionMode) {
                                notifier.toggleSelection(report.id);
                              } else {
                                widget.onReportTap(report.id, report.status);
                              }
                            },
                            onLongPress: () {
                              if (!state.isSelectionMode) {
                                try {
                                  notifier.toggleSelectionMode(report.id);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
        floatingActionButton: widget.floatingActionButton,
        bottomNavigationBar: state.isSelectionMode
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Text(
                        '${state.selectedReportIds.length} Dipilih',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => notifier.exitSelectionMode(),
                        child: const Text('Batal'),
                      ),
                      const Gap(8),
                      ElevatedButton(
                        onPressed: state.selectedReportIds.length < 2
                            ? null
                            : () {
                                // Implement grouping action
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Fitur Grouping (Coming Soon)',
                                    ),
                                  ),
                                );
                                notifier.exitSelectionMode();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.supervisorColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Gabungkan'),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
