import '../enums/report_status.dart';
import 'report_log.dart';

/// Shared Report model used across all roles
class Report {
  final String id;
  final String title;
  final String description;
  final String category;
  final String building;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final List<String>? mediaUrls; // Photo/video evidence
  final ReportStatus status;
  final bool isEmergency;
  final DateTime createdAt;

  // Reporter info
  final String reporterId;
  final String reporterName;
  final String? reporterEmail;
  final String? reporterPhone;

  // Handler info (teknisi)
  final List<String>? handledBy;

  // Supervisor info
  final String? supervisorId;
  final String? supervisorName;

  // Hold/Pause info
  final DateTime? pausedAt;
  final int totalPausedDurationSeconds; // Stored as seconds
  final String? holdReason;
  final String? holdPhoto;

  // Timeline logs
  final List<ReportLog> logs;

  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.building,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.mediaUrls,
    required this.status,
    this.isEmergency = false,
    required this.createdAt,
    required this.reporterId,
    required this.reporterName,
    this.reporterEmail,
    this.reporterPhone,
    this.handledBy,
    this.supervisorId,
    this.supervisorName,
    this.pausedAt,
    this.totalPausedDurationSeconds = 0,
    this.holdReason,
    this.holdPhoto,
    this.logs = const [],
  });

  /// Get elapsed time since creation (accounting for pauses)
  Duration get elapsed {
    final now = DateTime.now();
    final rawDuration = now.difference(createdAt);

    // If currently paused, subtract the time since pause started
    final currentPauseDuration = pausedAt != null
        ? now.difference(pausedAt!)
        : Duration.zero;

    final totalPause =
        Duration(seconds: totalPausedDurationSeconds) + currentPauseDuration;

    return rawDuration - totalPause;
  }

  /// Check if report is being actively handled
  bool get isActive => status.isActive;

  /// Check if report needs supervisor attention
  bool get needsSupervisorReview => status.needsSupervisorReview;

  /// Get the latest log entry
  ReportLog? get latestLog => logs.isNotEmpty ? logs.first : null;

  /// Create a copy with updated fields
  Report copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? building,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? mediaUrls,
    ReportStatus? status,
    bool? isEmergency,
    DateTime? createdAt,
    String? reporterId,
    String? reporterName,
    String? reporterEmail,
    String? reporterPhone,
    List<String>? handledBy,
    String? supervisorId,
    String? supervisorName,
    DateTime? pausedAt,
    int? totalPausedDurationSeconds,
    String? holdReason,
    String? holdPhoto,
    List<ReportLog>? logs,
    bool clearPausedAt = false,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      building: building ?? this.building,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      status: status ?? this.status,
      isEmergency: isEmergency ?? this.isEmergency,
      createdAt: createdAt ?? this.createdAt,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      handledBy: handledBy ?? this.handledBy,
      supervisorId: supervisorId ?? this.supervisorId,
      supervisorName: supervisorName ?? this.supervisorName,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      totalPausedDurationSeconds:
          totalPausedDurationSeconds ?? this.totalPausedDurationSeconds,
      holdReason: holdReason ?? this.holdReason,
      holdPhoto: holdPhoto ?? this.holdPhoto,
      logs: logs ?? this.logs,
    );
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      building: json['building'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      imageUrl: json['imageUrl'] as String?,
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)?.cast<String>(),
      status: ReportStatus.values.byName(json['status'] as String),
      isEmergency: json['isEmergency'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reporterId: json['reporterId'] as String,
      reporterName: json['reporterName'] as String,
      reporterEmail: json['reporterEmail'] as String?,
      reporterPhone: json['reporterPhone'] as String?,
      handledBy: (json['handledBy'] as List<dynamic>?)?.cast<String>(),
      supervisorId: json['supervisorId'] as String?,
      supervisorName: json['supervisorName'] as String?,
      pausedAt: json['pausedAt'] != null
          ? DateTime.parse(json['pausedAt'] as String)
          : null,
      totalPausedDurationSeconds:
          json['totalPausedDurationSeconds'] as int? ?? 0,
      holdReason: json['holdReason'] as String?,
      holdPhoto: json['holdPhoto'] as String?,
      logs:
          (json['logs'] as List<dynamic>?)
              ?.map((e) => ReportLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'building': building,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'mediaUrls': mediaUrls,
      'status': status.name,
      'isEmergency': isEmergency,
      'createdAt': createdAt.toIso8601String(),
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'reporterPhone': reporterPhone,
      'handledBy': handledBy,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'pausedAt': pausedAt?.toIso8601String(),
      'totalPausedDurationSeconds': totalPausedDurationSeconds,
      'holdReason': holdReason,
      'holdPhoto': holdPhoto,
      'logs': logs.map((e) => e.toJson()).toList(),
    };
  }
}
