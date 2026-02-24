import 'package:flutter/material.dart';
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

  // Filters
  final String search;
  final String? category;
  final String? location;
  final bool? isEmergency;
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;

  TeknisiReportsState({
    required this.reports,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.search = '',
    this.category,
    this.location,
    this.isEmergency,
    this.period,
    this.startDate,
    this.endDate,
  });

  TeknisiReportsState copyWith({
    List<Report>? reports,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? search,
    String? category,
    String? location,
    bool? isEmergency,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TeknisiReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
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

class TeknisiReportsNotifier extends Notifier<TeknisiReportsState> {
  final String status;

  TeknisiReportsNotifier(this.status);

  @override
  TeknisiReportsState build() {
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
        search: state.search.isNotEmpty ? state.search : null,
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
      debugPrint('Error loading teknisi reports ($status): $e');
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
}

final teknisiReportsProvider =
    NotifierProvider.family<
      TeknisiReportsNotifier,
      TeknisiReportsState,
      String
    >((status) {
      return TeknisiReportsNotifier(status);
    });
