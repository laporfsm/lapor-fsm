import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';

class TeknisiReportsState {
  final List<Report> reports;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  TeknisiReportsState({
    required this.reports,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  TeknisiReportsState copyWith({
    List<Report>? reports,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return TeknisiReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

class TeknisiReportsNotifier extends Notifier<TeknisiReportsState> {
  final String status;

  TeknisiReportsNotifier(this.status);

  @override
  TeknisiReportsState build() {
    // Initial fetch using microtask to avoid side effects during build
    Future.microtask(() => loadReports());
    return TeknisiReportsState(reports: []);
  }

  Future<void> loadReports({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        currentPage: 1,
        hasMore: true,
        reports: [],
        error: null,
      );
    } else if (state.isLoadingMore || !state.hasMore) {
      return;
    } else if (state.reports.isNotEmpty) {
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final response = await reportService.getStaffReports(
        role: 'technician',
        status: status,
        page: state.currentPage,
        limit: 10,
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
      debugPrint('Error loading teknisi reports ($status): $e');
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Gagal memuat data: $e',
      );
    }
  }

  Future<void> refresh() => loadReports(refresh: true);
}

final teknisiReportsProvider =
    NotifierProvider.family<
      TeknisiReportsNotifier,
      TeknisiReportsState,
      String
    >((status) {
      return TeknisiReportsNotifier(status);
    });
