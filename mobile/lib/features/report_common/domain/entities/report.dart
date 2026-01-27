import '../enums/report_status.dart';
import '../../../../core/models/report_log.dart'; // Keep pointing to core for logs for now, or migrate logs too? Plan didn't specify logs migration but it makes sense. I will keep it pointing to core for now to minimize breakage scope in one step, or I can copy ReportLog too if needed. Let's keep ReportLog in core for a moment or check if it needs moving. Plan didn't explicitly say "Move ReportLog", but "Report model". I will update import to relative if I move ReportLog, but for now I'll assume ReportLog stays or I will move it in next step. Wait, `report.dart` import `report_log.dart`. It's better to move ReportLog too if it's tightly coupled.

// Re-reading plan: "Migrate Report model". Usually implies dependencies too.
// I will check if ReportLog is used elsewhere.
// For now, I will import ReportLog from core (I will fix import path).
// Actually, I should probably move ReportLog to `entities` as well or `core`.
// Let's stick to the plan: Migrate Report.
// I'll update the import to point to the old location for ReportLog for now if I don't move it,
// OR I can duplicate/move ReportLog now. I'll stick to pointing to core to be safe,
// using relative path `../../../../core/models/report_log.dart`.

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

  // PJ Gedung info (New)
  final String? pjGedungId;
  final String? pjGedungName;
  final DateTime? verifiedAt;

  // Handler info (teknisi)
  final List<String>? handledBy;
  final DateTime? assignedAt; // When assigned to technician
  final DateTime? handlingStartedAt; // When technician starts work
  final DateTime? completedAt; // When technician marks as complete

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
    this.pjGedungId,
    this.pjGedungName,
    this.verifiedAt,
    this.handledBy,
    this.assignedAt,
    this.handlingStartedAt,
    this.completedAt,
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
  bool get isActive => status
      .isTechnicianActive; // Updated to use new extension getter name if needed, or stick to isActive. Extension had isTechnicianActive and isActive. `status.isActive` in extension means "not final". `isTechnicianActive` means "working on it". The old code had `status.isActive`. I should check what the old extension did.
  // Old extension: isActive => status.isActive.
  // usage: bool get isActive => status.isActive;
  // I will map it to the definition in my new extension.
  // In new extension: isActive => !approved && !archived.

  /// Check if report needs supervisor attention
  bool get needsSupervisorReview =>
      status == ReportStatus.selesai ||
      status ==
          ReportStatus.ditolak; // Using logic from extension or defining here.
  // Better to delegate to extension if possible, but Report model shouldn't necessarily depend on UI extension logic methods if they are in utils, but here the enum and extension are in domain. So I can use them.
  // BUT `ReportStatus` is imported. does it have the extension visible? Yes if in same file or imported.
  // I defined extension in `report_status.dart`.

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
    String? pjGedungId,
    String? pjGedungName,
    DateTime? verifiedAt,
    List<String>? handledBy,
    DateTime? assignedAt,
    DateTime? handlingStartedAt,
    DateTime? completedAt,
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
      pjGedungId: pjGedungId ?? this.pjGedungId,
      pjGedungName: pjGedungName ?? this.pjGedungName,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      handledBy: handledBy ?? this.handledBy,
      assignedAt: assignedAt ?? this.assignedAt,
      handlingStartedAt: handlingStartedAt ?? this.handlingStartedAt,
      completedAt: completedAt ?? this.completedAt,
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

  // Json serialization... (keeping simple or using freezed? Current code uses manual fromJson)
  // I will update fromJson to include new fields

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
      pjGedungId: json['pjGedungId'] as String?,
      pjGedungName: json['pjGedungName'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
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
      'pjGedungId': pjGedungId,
      'pjGedungName': pjGedungName,
      'verifiedAt': verifiedAt?.toIso8601String(),
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
