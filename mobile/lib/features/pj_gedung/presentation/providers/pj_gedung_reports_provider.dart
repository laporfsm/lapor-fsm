import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/services/auth_service.dart';

class PjGedungReportsState {
  final List<Report> reports;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final int currentPage;
  final int totalReports;
  final String searchQuery;
  final Set<String> selectedStatuses;
  final bool emergencyOnly;
  final String? periodFilter;
  final DateTimeRange? customDateRange;
  final String? error;

  PjGedungReportsState({
    this.reports = const [],
    this.isLoading = true,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.totalReports = 0,
    this.searchQuery = '',
    this.selectedStatuses = const {},
    this.emergencyOnly = false,
    this.periodFilter,
    this.customDateRange,
    this.error,
  });

  PjGedungReportsState copyWith({
    List<Report>? reports,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    int? currentPage,
    int? totalReports,
    String? searchQuery,
    Set<String>? selectedStatuses,
    bool? emergencyOnly,
    String? periodFilter,
    DateTimeRange? customDateRange,
    String? error,
  }) {
    return PjGedungReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalReports: totalReports ?? this.totalReports,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      emergencyOnly: emergencyOnly ?? this.emergencyOnly,
      periodFilter: periodFilter ?? this.periodFilter,
      customDateRange: customDateRange ?? this.customDateRange,
      error: error,
    );
  }
}

class PjGedungReportsNotifier extends Notifier<PjGedungReportsState> {
  final String statusArg;

  PjGedungReportsNotifier(this.statusArg);

  @override
  PjGedungReportsState build() {
    return PjGedungReportsState();
  }

  final int _limit = 20;

  Future<void> fetchReports({bool isRefresh = true}) async {
    if (isRefresh) {
      state = state.copyWith(
        isLoading: true,
        currentPage: 1,
        hasMore: true,
        error: null,
      );
    } else {
      if (state.isFetchingMore || !state.hasMore) return;
      state = state.copyWith(isFetchingMore: true);
    }

    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final location = user['department'];

        String? startDate;
        String? endDate;

        if (state.customDateRange != null) {
          startDate = state.customDateRange!.start.toIso8601String();
          endDate = state.customDateRange!.end.toIso8601String();
        } else if (state.periodFilter != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          switch (state.periodFilter) {
            case 'today':
              startDate = today.toIso8601String();
              break;
            case 'week':
              startDate = today
                  .subtract(const Duration(days: 7))
                  .toIso8601String();
              break;
            case 'month':
              startDate = DateTime(
                now.year,
                now.month - 1,
                now.day,
              ).toIso8601String();
              break;
          }
        }

        // Determine status query:
        // 1. If state.selectedStatuses is set (via filter UI), use that.
        // 2. Else if the family arg 'statusArg' (base status) is provided, use that.
        // 3. Otherwise default to a broad set of statuses.
        String statusQuery;
        if (state.selectedStatuses.isNotEmpty) {
          statusQuery = state.selectedStatuses.join(',');
        } else if (statusArg.isNotEmpty) {
          statusQuery = statusArg;
        } else {
          // Fallback default if needed, though usually statusArg will be provided or empty means "all"
          statusQuery =
              'terverifikasi,verifikasi,diproses,penanganan,onHold,selesai,approved,ditolak,recalled,archived';
        }

        final response = await reportService.getStaffReports(
          role: 'pj',
          location: location,
          status: statusQuery,
          isEmergency: state.emergencyOnly ? true : null,
          search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
          startDate: startDate,
          endDate: endDate,
          period: state.periodFilter,
          page: state.currentPage,
          limit: _limit,
        );

        final List<Map<String, dynamic>> reportsData =
            List<Map<String, dynamic>>.from(response['data'] ?? []);
        final int total = response['total'] ?? 0;

        final newReports = reportsData
            .map((json) => Report.fromJson(json))
            .toList();

        final updatedReports = isRefresh
            ? newReports
            : [...state.reports, ...newReports];

        state = state.copyWith(
          reports: updatedReports,
          totalReports: total,
          hasMore: updatedReports.length < total,
          isLoading: false,
          isFetchingMore: false,
        );
      }
    } catch (e) {
      debugPrint('Error fetching pj reports: $e');
      state = state.copyWith(
        isLoading: false,
        isFetchingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchMore() async {
    if (state.isFetchingMore || !state.hasMore) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await fetchReports(isRefresh: false);
  }

  Future<void> refresh() async {
    await fetchReports(isRefresh: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchReports();
  }

  void setStatuses(Set<String> statuses) {
    state = state.copyWith(selectedStatuses: statuses);
    fetchReports();
  }

  void setEmergencyOnly(bool value) {
    state = state.copyWith(emergencyOnly: value);
    fetchReports();
  }

  void setPeriodFilter(String? period) {
    state = state.copyWith(periodFilter: period, customDateRange: null);
    fetchReports();
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(customDateRange: range, periodFilter: null);
    fetchReports();
  }

  void setFilters({
    String?
    category, // Not used in API yet for PJ but kept for consistency if needed
    String? location,
    bool? isEmergency,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    DateTimeRange? range;
    if (startDate != null && endDate != null) {
      range = DateTimeRange(start: startDate, end: endDate);
    }

    state = state.copyWith(
      emergencyOnly: isEmergency ?? state.emergencyOnly,
      periodFilter: period ?? state.periodFilter,
      customDateRange: range ?? state.customDateRange,
    );
    fetchReports();
  }

  void resetFilters() {
    state = PjGedungReportsState(isLoading: true);
    fetchReports();
  }
}

final pjGedungReportsProvider =
    NotifierProvider.family<
      PjGedungReportsNotifier,
      PjGedungReportsState,
      String
    >((status) {
      return PjGedungReportsNotifier(status);
    });
