import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';

class TeknisiDashboardState {
  final bool isLoading;
  final Map<String, int> stats;
  final List<Report> readyReports;
  final List<Report> activeReports;
  final int? currentStaffId;
  final String? error;

  TeknisiDashboardState({
    this.isLoading = true,
    this.stats = const {
      'diproses': 0,
      'penanganan': 0,
      'onHold': 0,
      'selesai': 0,
      'recalled': 0,
      'todayReports': 0,
      'weekReports': 0,
      'monthReports': 0,
      'emergency': 0,
    },
    this.readyReports = const [],
    this.activeReports = const [],
    this.currentStaffId,
    this.error,
  });

  TeknisiDashboardState copyWith({
    bool? isLoading,
    Map<String, int>? stats,
    List<Report>? readyReports,
    List<Report>? activeReports,
    int? currentStaffId,
    String? error,
  }) {
    return TeknisiDashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      readyReports: readyReports ?? this.readyReports,
      activeReports: activeReports ?? this.activeReports,
      currentStaffId: currentStaffId ?? this.currentStaffId,
      error: error ?? this.error,
    );
  }
}

class TeknisiDashboardNotifier extends Notifier<TeknisiDashboardState> {
  Timer? _refreshTimer;

  @override
  TeknisiDashboardState build() {
    _startTimer();
    ref.onDispose(() => _refreshTimer?.cancel());

    // Initial fetch
    Future.microtask(() => loadData());

    return TeknisiDashboardState();
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadData(silent: true);
    });
  }

  Future<void> loadData({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await authService.getCurrentUser();
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'User not found');
        return;
      }

      final staffIdStr = user['id'].toString();
      final staffId = int.tryParse(staffIdStr) ?? 0;

      // Fetch stats and lists in parallel
      final results = await Future.wait([
        reportService.getTechnicianDashboardStats(staffIdStr),
        // Siap Dimulai: Personal Diproses
        reportService.getStaffReports(
          role: 'technician',
          status: 'diproses',
          assignedTo: staffId,
        ),
        // Siap Dimulai: Personal Recalled
        reportService.getStaffReports(
          role: 'technician',
          status: 'recalled',
          assignedTo: staffId,
        ),
        // Sedang Dikerjakan: Personal Penanganan
        reportService.getStaffReports(
          role: 'technician',
          status: 'penanganan',
          assignedTo: staffId,
        ),
      ]);

      final statsData = results[0] != null
          ? Map<String, int>.from(results[0] as Map)
          : state.stats;

      final diprosesResponse = results[1] as Map<String, dynamic>;
      final diproses = (diprosesResponse['data'] as List? ?? [])
          .map((json) => Report.fromJson(json))
          .toList();

      final recalledResponse = results[2] as Map<String, dynamic>;
      final recalled = (recalledResponse['data'] as List? ?? [])
          .map((json) => Report.fromJson(json))
          .toList();

      // Merge and sort
      final readyReports = [...recalled, ...diproses]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final activeResponse = results[3] as Map<String, dynamic>;
      final activeReports =
          (activeResponse['data'] as List? ?? [])
              .map((json) => Report.fromJson(json))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        isLoading: false,
        stats: statsData,
        readyReports: readyReports,
        activeReports: activeReports,
        currentStaffId: staffId,
      );
    } catch (e) {
      debugPrint('Error loading Technician dashboard data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadData();
}

final teknisiDashboardProvider =
    NotifierProvider<TeknisiDashboardNotifier, TeknisiDashboardState>(() {
      return TeknisiDashboardNotifier();
    });
