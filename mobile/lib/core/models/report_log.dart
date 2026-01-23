import '../enums/report_status.dart';

/// Log entry for report timeline transparency
class ReportLog {
  final String id;
  final ReportStatus fromStatus;
  final ReportStatus toStatus;
  final ReportAction action;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String? reason;
  final List<String>? mediaUrls; // Evidence media for this action
  final DateTime timestamp;

  const ReportLog({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    this.reason,
    this.mediaUrls,
    required this.timestamp,
  });

  /// Generate human-readable log message
  String get message {
    final actor = '$actorName ($actorRole)';
    final reasonText = reason != null ? ': $reason' : '';

    switch (action) {
      case ReportAction.created:
        return 'Laporan dibuat oleh $actor';
      case ReportAction.verified:
        return 'Laporan diverifikasi oleh $actor';
      case ReportAction.handling:
        return 'Penanganan dimulai oleh $actor';
      case ReportAction.completed:
        return 'Laporan diselesaikan oleh $actor$reasonText';
      case ReportAction.rejected:
        return 'Laporan ditolak oleh $actor$reasonText';
      case ReportAction.approved:
        return 'Laporan disetujui oleh $actor';
      case ReportAction.recalled:
        return 'Laporan di-recall oleh $actor$reasonText';
      case ReportAction.overrideRejection:
        return 'Penolakan dibatalkan oleh $actor$reasonText';
      case ReportAction.approveRejection:
        return 'Penolakan disetujui oleh $actor$reasonText';
      case ReportAction.archived:
        return 'Laporan diarsipkan oleh $actor';
      case ReportAction.paused:
        return 'Pengerjaan dipause oleh $actor$reasonText';
      case ReportAction.resumed:
        return 'Pengerjaan dilanjutkan oleh $actor';
    }
  }

  factory ReportLog.fromJson(Map<String, dynamic> json) {
    return ReportLog(
      id: json['id'] as String,
      fromStatus: ReportStatus.values.byName(json['fromStatus'] as String),
      toStatus: ReportStatus.values.byName(json['toStatus'] as String),
      action: ReportAction.values.byName(json['action'] as String),
      actorId: json['actorId'] as String,
      actorName: json['actorName'] as String,
      actorRole: json['actorRole'] as String,
      reason: json['reason'] as String?,
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)?.cast<String>(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromStatus': fromStatus.name,
      'toStatus': toStatus.name,
      'action': action.name,
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'reason': reason,
      'mediaUrls': mediaUrls,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Actions that can be performed on a report
enum ReportAction {
  created,
  verified,
  handling,
  completed,
  rejected,
  approved,
  recalled,
  overrideRejection,
  approveRejection,
  archived,
  paused,
  resumed,
}
