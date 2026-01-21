/// User role enum with permission definitions
enum UserRole { pelapor, teknisi, supervisor, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.pelapor:
        return 'Pelapor';
      case UserRole.teknisi:
        return 'Teknisi';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  // Permission checks
  bool get canCreateReport => this == UserRole.pelapor;

  bool get canViewPublicFeed => this == UserRole.pelapor;

  bool get canViewOwnReports => this == UserRole.pelapor;

  bool get canViewAllReports =>
      this == UserRole.teknisi || this == UserRole.supervisor;

  bool get canVerifyReport => this == UserRole.teknisi;

  bool get canHandleReport => this == UserRole.teknisi;

  bool get canRejectReport => this == UserRole.teknisi;

  bool get canCompleteReport => this == UserRole.teknisi;

  bool get canReviewCompletion => this == UserRole.supervisor;

  bool get canApproveReport => this == UserRole.supervisor;

  bool get canRecallReport => this == UserRole.supervisor;

  bool get canReviewRejection => this == UserRole.supervisor;

  bool get canOverrideRejection => this == UserRole.supervisor;

  bool get canArchiveReport => this == UserRole.supervisor;

  bool get canExportReports => this == UserRole.supervisor;

  bool get canMonitorTechnicians => this == UserRole.supervisor;

  bool get canContactReporter =>
      this == UserRole.teknisi || this == UserRole.supervisor;

  bool get canViewMap =>
      this == UserRole.teknisi || this == UserRole.supervisor;
}
