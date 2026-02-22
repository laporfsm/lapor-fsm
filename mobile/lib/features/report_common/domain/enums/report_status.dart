/// Report status enum representing the lifecycle of a report
///
/// Flow:
/// PENDING (Verif PJ) → TERVERIFIKASI (Verif Supervisor) → DIPROSES (Tunggu Teknisi)
/// → PENANGANAN (Kerja) → SELESAI (Tunggu Approval) → APPROVED (Closed)
///
/// Side Flows:
/// - ONHOLD (Pause)
/// - DITOLAK (Legacy/Optional)
/// - RECALLED (Supervisor minta revisi ke Teknisi)
library;

import 'dart:ui';

enum ReportStatus {
  /// Baru dibuat pelapor, menunggu verifikasi PJ Gedung
  pending,

  /// Sudah diverifikasi PJ Gedung, menunggu alokasi dari Supervisor
  terverifikasi,

  /// (Legacy) Sedang diverifikasi teknisi - maintained for backward compatibility mapping
  verifikasi,

  /// Sudah dialokasikan Supervisor, menunggu konfirmasi Teknisi
  diproses,

  /// Sedang dikerjakan oleh Teknisi
  penanganan,

  /// Ditunda/Pause oleh Teknisi
  onHold,

  /// Selesai dikerjakan Teknisi, menunggu Approval Supervisor
  selesai,

  /// Disetujui Supervisor / PJ Gedung (CLOSED)
  approved,

  /// Ditolak (Legacy/Optional)
  ditolak,

  /// Dikembalikan ke Teknisi untuk revisi
  recalled,

  /// Final state legacy
  archived,
}

extension ReportStatusX on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Menunggu Verifikasi';
      case ReportStatus.terverifikasi:
        return 'Terverifikasi';
      case ReportStatus.verifikasi: // Legacy mapping
        return 'Terverifikasi';
      case ReportStatus.diproses:
        return 'Diproses';
      case ReportStatus.penanganan:
        return 'Penanganan';
      case ReportStatus.onHold:
        return 'On Hold';
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

  /// Whether the report is currently in an active handling state by Technician
  bool get isTechnicianActive =>
      this == ReportStatus.penanganan ||
      this == ReportStatus.onHold ||
      this == ReportStatus.recalled;

  /// Whether the report is waiting for someone's action
  bool get isActive =>
      this != ReportStatus.approved &&
      this != ReportStatus.ditolak &&
      this != ReportStatus.archived;

  bool get isFinal =>
      this == ReportStatus.approved ||
      this == ReportStatus.archived ||
      this == ReportStatus.ditolak;

  Color get color {
    // We can define semantic colors here later or use a helper
    return switch (this) {
      ReportStatus.pending => const Color(0xFF9E9E9E), // Grey
      ReportStatus.terverifikasi => const Color(0xFF2196F3), // Blue
      ReportStatus.verifikasi => const Color(0xFF2196F3), // Blue
      ReportStatus.diproses => const Color(0xFF9C27B0), // Purple
      ReportStatus.penanganan => const Color(0xFFFF9800), // Orange
      ReportStatus.onHold => const Color(0xFFFF5722), // Deep Orange
      ReportStatus.selesai => const Color(0xFF009688), // Teal
      ReportStatus.approved => const Color(0xFF4CAF50), // Green
      ReportStatus.ditolak => const Color(0xFFF44336), // Red
      ReportStatus.recalled => const Color(0xFFE91E63), // Pink
      ReportStatus.archived => const Color(0xFF607D8B), // Blue Grey
    };
  }
}
