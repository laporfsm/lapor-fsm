import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';

class ReportDetailState {
  final Report? report;
  final bool isLoading;
  final bool isProcessing;
  final String? error;

  ReportDetailState({
    this.report,
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
  });

  ReportDetailState copyWith({
    Report? report,
    bool? isLoading,
    bool? isProcessing,
    String? error,
  }) {
    return ReportDetailState(
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
    );
  }
}

class ReportDetailNotifier extends Notifier<ReportDetailState> {
  final String reportId;

  ReportDetailNotifier(this.reportId);

  @override
  ReportDetailState build() {
    // Initial fetch using microtask to avoid side effects during build
    Future.microtask(() => fetchReport());
    return ReportDetailState(isLoading: true);
  }

  Future<void> fetchReport() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await reportService.getReportDetail(reportId);
      if (data != null) {
        state = state.copyWith(report: Report.fromJson(data), isLoading: false);
      } else {
        state = state.copyWith(
          error: 'Laporan tidak ditemukan',
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('Error fetching report detail ($reportId): $e');
      state = state.copyWith(
        error: 'Gagal memuat detail laporan',
        isLoading: false,
      );
    }
  }

  Future<void> acceptTask(int staffId) async {
    if (state.report == null) return;
    state = state.copyWith(isProcessing: true);
    try {
      await reportService.acceptTask(state.report!.id, staffId);
      await fetchReport();
    } catch (e) {
      debugPrint('Error accepting task: $e');
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> pauseTask(int staffId, String reason) async {
    if (state.report == null) return;
    state = state.copyWith(isProcessing: true);
    try {
      await reportService.pauseTask(state.report!.id, staffId, reason);
      await fetchReport();
    } catch (e) {
      debugPrint('Error pausing task: $e');
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> resumeTask(int staffId) async {
    if (state.report == null) return;
    state = state.copyWith(isProcessing: true);
    try {
      await reportService.resumeTask(state.report!.id, staffId);
      await fetchReport();
    } catch (e) {
      debugPrint('Error resuming task: $e');
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }
}

final reportDetailProvider =
    NotifierProvider.family<ReportDetailNotifier, ReportDetailState, String>((
      reportId,
    ) {
      return ReportDetailNotifier(reportId);
    });
