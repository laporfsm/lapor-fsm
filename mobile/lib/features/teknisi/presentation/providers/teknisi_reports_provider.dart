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
  final List<String> categories;
  final List<String> locations;
  final bool? isEmergency;
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? assignedTo;
  final String? selectedStatus;

  TeknisiReportsState({
    required this.reports,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.search = '',
    this.categories = const [],
    this.locations = const [],
    this.isEmergency,
    this.period,
    this.startDate,
    this.endDate,
    this.assignedTo,
    this.selectedStatus,
  });

  TeknisiReportsState copyWith({
    List<Report>? reports,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? search,
    List<String>? categories,
    List<String>? locations,
    bool? isEmergency,
    bool clearEmergency = false,
    String? period,
    bool clearPeriod = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    int? assignedTo,
    String? selectedStatus,
    bool clearSelectedStatus = false,
  }) {
    return TeknisiReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
      search: search ?? this.search,
      categories: categories ?? this.categories,
      locations: locations ?? this.locations,
      isEmergency: clearEmergency ? null : (isEmergency ?? this.isEmergency),
      period: clearPeriod ? null : (period ?? this.period),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      assignedTo: assignedTo ?? this.assignedTo,
      selectedStatus: clearSelectedStatus ? null : (selectedStatus ?? this.selectedStatus),
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
        status: state.selectedStatus ?? status,
        page: state.currentPage,
        limit: 10,
        search: state.search.isNotEmpty ? state.search : null,
        category: state.categories.isNotEmpty ? state.categories.join(',') : null,
        location: state.locations.isNotEmpty ? state.locations.join(',') : null,
        isEmergency: state.isEmergency,
        period: state.period,
        startDate: state.startDate?.toIso8601String(),
        endDate: state.endDate?.toIso8601String(),
        assignedTo: state.assignedTo,
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
    List<String>? categories,
    List<String>? locations,
    bool? isEmergency,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    int? assignedTo,
    String? selectedStatus,
  }) {
    state = state.copyWith(
      categories: categories ?? state.categories,
      locations: locations ?? state.locations,
      isEmergency: isEmergency,
      clearEmergency: isEmergency == null,
      period: period,
      clearPeriod: period == null,
      startDate: startDate,
      clearStartDate: startDate == null,
      endDate: endDate,
      clearEndDate: endDate == null,
      assignedTo: assignedTo ?? state.assignedTo,
      selectedStatus: selectedStatus ?? state.selectedStatus,
      clearSelectedStatus: selectedStatus == null,
    );
    loadReports(refresh: true);
  }

  void clearFilters() {
    state = TeknisiReportsState(
      reports: state.reports,
      isLoading: state.isLoading,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      currentPage: state.currentPage,
      error: state.error,
      assignedTo: state.assignedTo,
      search: '',
      categories: [],
      locations: [],
      isEmergency: null,
      period: null,
      startDate: null,
      endDate: null,
      selectedStatus: null,
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
