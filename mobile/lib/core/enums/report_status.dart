/// Report status enum representing the lifecycle of a report
///
/// Flow:
/// PENDING → VERIFIKASI → PENANGANAN → SELESAI → APPROVED → ARCHIVED
///               ↓                         ↓
///           DITOLAK                   RECALLED
///               ↓                         ↓
///     [Supervisor Review]         [Back to PENANGANAN]
///          ↓      ↓
///      ARCHIVED  PENDING (with LOG)
library;

enum ReportStatus {
  /// Newly created or returned by supervisor
  pending,

  /// Being verified by technician
  verifikasi,

  /// Being handled by technician
  penanganan,

  /// Marked complete, awaiting supervisor approval
  selesai,

  /// Approved by supervisor
  approved,

  /// Rejected by technician, awaiting supervisor review
  ditolak,

  /// Recalled by supervisor, returned to technician
  recalled,

  /// Final state - archived
  archived,
}

extension ReportStatusX on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.verifikasi:
        return 'Verifikasi';
      case ReportStatus.penanganan:
        return 'Penanganan';
      case ReportStatus.selesai:
        return 'Selesai';
      case ReportStatus.approved:
        return 'Approved';
      case ReportStatus.ditolak:
        return 'Ditolak';
      case ReportStatus.recalled:
        return 'Recalled';
      case ReportStatus.archived:
        return 'Arsip';
    }
  }

  bool get isActive =>
      this == ReportStatus.verifikasi ||
      this == ReportStatus.penanganan ||
      this == ReportStatus.recalled;

  bool get isFinal =>
      this == ReportStatus.approved || this == ReportStatus.archived;

  bool get needsSupervisorReview =>
      this == ReportStatus.selesai || this == ReportStatus.ditolak;
}
