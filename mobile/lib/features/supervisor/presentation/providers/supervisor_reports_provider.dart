import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';

class SupervisorReportsState {
  final List<Report> reports;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  // Selection Mode State
  final bool isSelectionMode;
  final Set<String> selectedReportIds;

  // Filters
  final String search;
  final String? category;
  final String? location;
  final bool? isEmergency;
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;

  SupervisorReportsState({
    required this.reports,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.isSelectionMode = false,
    this.selectedReportIds = const {},
    this.search = '',
    this.category,
    this.location,
    this.isEmergency,
    this.period,
    this.startDate,
    this.endDate,
  });

  SupervisorReportsState copyWith({
    List<Report>? reports,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool? isSelectionMode,
    Set<String>? selectedReportIds,
    String? search,
    String? category,
    String? location,
    bool? isEmergency,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return SupervisorReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedReportIds: selectedReportIds ?? this.selectedReportIds,
      search: search ?? this.search,
      category: category ?? this.category,
      location: location ?? this.location,
      isEmergency: isEmergency ?? this.isEmergency,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class SupervisorReportsNotifier extends Notifier<SupervisorReportsState> {
  final String status;

  SupervisorReportsNotifier(this.status);

  @override
  SupervisorReportsState build() {
    return SupervisorReportsState(reports: []);
  }

  Future<void> loadReports({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        currentPage: 1,
        hasMore: true,
        reports: [],
        error: null,
        isSelectionMode: false,
        selectedReportIds: {},
      );
    } else if (state.isLoadingMore || !state.hasMore) {
      return;
    } else if (state.reports.isNotEmpty) {
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      // Use getStaffReports with role='supervisor'
      final response = await reportService.getStaffReports(
        role: 'supervisor',
        status: status,
        page: state.currentPage,
        limit: 10,
        search: state.search,
        category: state.category,
        location: state.location,
        isEmergency: state.isEmergency,
        period: state.period,
        startDate: state.startDate?.toIso8601String(),
        endDate: state.endDate?.toIso8601String(),
      );

      final List<dynamic> docs = response['data'] ?? [];
      final List<Report> newReports = docs
          .map((json) => Report.fromJson(json))
          .toList();

      final int total = response['total'] ?? 0;
      final bool hasMore = state.reports.length + newReports.length < total;

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        reports: refresh ? newReports : [...state.reports, ...newReports],
        hasMore: hasMore,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      debugPrint('Error loading supervisor reports ($status): $e');
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Gagal memuat data: $e',
      );
    }
  }

  Future<void> refresh() => loadReports(refresh: true);

  void setSearch(String query) {
    state = state.copyWith(search: query);
    loadReports(refresh: true);
  }

  void setFilters({
    String? category,
    String? location,
    bool? isEmergency,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    state = state.copyWith(
      category: category,
      location: location,
      isEmergency: isEmergency,
      period: period,
      startDate: startDate,
      endDate: endDate,
    );
    loadReports(refresh: true);
  }

  void clearFilters() {
    state = state.copyWith(
      search: '',
      category: null,
      location: null,
      isEmergency: null,
      period: null,
      startDate: null,
      endDate: null,
    );
    loadReports(refresh: true);
  }

  // Selection Mode Logic
  void toggleSelectionMode(String reportId) {
    // Only verify allowed statuses for grouping if needed, but UI usually filters actions.
    // For now, allow selection logic to proceed.
    final report = state.reports.firstWhere((r) => r.id == reportId);

    // Check if mergeable (Pending or Verified)
    if (!_isReportMergeable(report)) {
      throw Exception(
        'Laporan ini tidak dapat digabungkan (Status harus Menunggu Verifikasi/Terverifikasi)',
      );
    }

    state = state.copyWith(
      isSelectionMode: true,
      selectedReportIds: {reportId},
    );
  }

  void toggleSelection(String reportId) {
    if (!state.isSelectionMode) return;

    final currentSelected = Set<String>.from(state.selectedReportIds);
    if (currentSelected.contains(reportId)) {
      currentSelected.remove(reportId);
      if (currentSelected.isEmpty) {
        state = state.copyWith(isSelectionMode: false, selectedReportIds: {});
      } else {
        state = state.copyWith(selectedReportIds: currentSelected);
      }
      return;
    }

    // Validation
    final report = state.reports.firstWhere((r) => r.id == reportId);
    if (!_isReportMergeable(report)) {
      throw Exception('Status laporan tidak valid untuk digabungkan');
    }

    // Check location match with first selected
    if (currentSelected.isNotEmpty) {
      final firstId = currentSelected.first;
      final firstReport = state.reports.firstWhere((r) => r.id == firstId);
      if (report.location != firstReport.location) {
        throw Exception(
          'Lokasi harus sama dengan laporan pertama (${firstReport.location})',
        );
      }
    }

    currentSelected.add(reportId);
    state = state.copyWith(selectedReportIds: currentSelected);
  }

  bool _isReportMergeable(Report report) {
    return report.status == ReportStatus.pending ||
        report.status == ReportStatus.terverifikasi ||
        report.status == ReportStatus.verifikasi;
  }

  void exitSelectionMode() {
    state = state.copyWith(isSelectionMode: false, selectedReportIds: {});
  }
}

final supervisorReportsProvider =
    NotifierProvider.family<
      SupervisorReportsNotifier,
      SupervisorReportsState,
      String
    >((status) {
      return SupervisorReportsNotifier(status);
    });
