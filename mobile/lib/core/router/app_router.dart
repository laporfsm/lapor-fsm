import 'package:go_router/go_router.dart';

import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/auth/presentation/pages/register_page.dart';
import 'package:mobile/features/auth/presentation/pages/email_verification_page.dart';
import 'package:mobile/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/pelapor_home_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/create_report_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/report_success_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/report_detail_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/profile/edit_profile_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/profile/settings_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/profile/help_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/emergency_report_page.dart';

// Teknisi imports
import 'package:mobile/features/teknisi/presentation/pages/dashboard/teknisi_home_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_report_detail_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_complete_report_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_map_view_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/setting/teknisi_edit_profile_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/setting/teknisi_setting_main_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/setting/teknisi_settings_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/setting/teknisi_help_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_all_reports_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_siap_dimulai_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_sedang_dikerjakan_page.dart';

import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_home_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/reports/pj_gedung_history_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/reports/pj_gedung_reports_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/reports/pj_gedung_report_detail_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/dashboard/pj_gedung_statistics_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/setting/pj_gedung_help_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/setting/pj_gedung_settings_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/setting/pj_gedung_edit_profile_page.dart';

// Supervisor imports
import 'package:mobile/features/supervisor/presentation/pages/dashboard/supervisor_shell_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_reports_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_review_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_archive_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_rejected_reports_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_export_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_non_gedung_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/staff/supervisor_technician_list_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/staff/supervisor_technician_detail_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/stats/supervisor_statistics_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/staff/supervisor_technician_form_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/supervisor_account_settings_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/support/supervisor_help_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/supervisor_setting_main_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/master_data/supervisor_categories_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/staff/supervisor_activity_log_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/master_data/supervisor_location_list_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/setting/staff/supervisor_pj_gedung_form_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/profile/supervisor_edit_profile_page.dart';

// Admin imports
import 'package:mobile/features/admin/presentation/widgets/admin_shell.dart';
import 'package:mobile/features/admin/presentation/pages/dashboard/admin_dashboard_page.dart';
import 'package:mobile/features/admin/presentation/pages/management/admin_users_page.dart';
import 'package:mobile/features/admin/presentation/pages/reports/admin_reports_page.dart';
import 'package:mobile/features/admin/presentation/pages/management/user_detail_page.dart';
import 'package:mobile/features/admin/presentation/pages/profile/admin_settings_page.dart';
import 'package:mobile/features/admin/presentation/pages/management/admin_statistics_page.dart';
import 'package:mobile/features/admin/presentation/pages/profile/admin_help_page.dart';
import 'package:mobile/features/admin/presentation/pages/reports/admin_report_detail_page.dart';
import 'package:mobile/features/admin/presentation/pages/management/admin_activity_log_page.dart';
import 'package:mobile/features/admin/presentation/pages/profile/admin_profile_page.dart';

// Auth & Common imports
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:mobile/features/auth/presentation/pages/reset_password_page.dart';
import 'package:mobile/features/notification/presentation/pages/notification_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final bool loggedIn = await authService.isLoggedIn();
    final String location = state.uri.path;

    // List of auth-related paths that should be accessible when NOT logged in
    final bool isAuthPath =
        location == '/login' ||
        location == '/register' ||
        location == '/forgot-password' ||
        location == '/reset-password' ||
        location == '/complete-profile';

    if (!loggedIn) {
      // If not logged in and not on an auth path, go to login
      return isAuthPath ? null : '/login';
    }

    // If logged in and on an auth path, redirect to appropriate home
    if (isAuthPath) {
      final user = await authService.getCurrentUser();
      final role = user?['role'];

      if (role == 'teknisi') return '/teknisi';
      if (role == 'supervisor') return '/supervisor';
      if (role == 'pj_gedung') return '/pj-gedung';
      if (role == 'admin') return '/admin/dashboard';
      return '/'; // Default for pelapor
    }

    // Special case for root path when logged in
    if (location == '/') {
      final user = await authService.getCurrentUser();
      final role = user?['role'];

      if (role == 'teknisi') return '/teknisi';
      if (role == 'supervisor') return '/supervisor';
      if (role == 'pj_gedung') return '/pj-gedung';
      if (role == 'admin') return '/admin/dashboard';
      // role == 'pelapor' stays at '/'
    }

    return null;
  },
  routes: [
    // Auth - Unified Login & Register
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfilePage(),
    ),
    GoRoute(
      path: '/email-verification',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return EmailVerificationPage(email: email);
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => ResetPasswordPage(
        token: state.uri.queryParameters['token'],
        email: state.uri.queryParameters['email'],
      ),
    ),

    // ===============================================
    // PELAPOR - Single route with IndexedStack navigation
    // ===============================================
    GoRoute(path: '/', builder: (context, state) => const PelaporHomePage()),

    // Report Flow - Pelapor (outside shell - no bottom nav during report creation)
    GoRoute(
      path: '/create-report',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return CreateReportPage(
          category: extra['category'] ?? 'Umum',
          isEmergency: extra['isEmergency'] ?? false,
          categoryId: extra['categoryId'],
        );
      },
    ),
    GoRoute(
      path: '/report-success',
      builder: (context, state) => const ReportSuccessPage(),
    ),
    GoRoute(
      path: '/report-detail/:id',
      builder: (context, state) =>
          ReportDetailPage(reportId: state.pathParameters['id'] ?? '0'),
    ),

    // Edit Profile - Pelapor (outside shell for focused editing)
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),

    // Settings - Pelapor
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    // Help - Pelapor
    GoRoute(path: '/help', builder: (context, state) => const HelpPage()),

    // Emergency Report - Pelapor (simplified fast reporting)
    GoRoute(
      path: '/emergency-report',
      builder: (context, state) => const EmergencyReportPage(),
    ),

    // ===============================================
    // TEKNISI ROUTES
    // ===============================================
    GoRoute(
      path: '/teknisi',
      builder: (context, state) => const TeknisiHomePage(),
    ),
    GoRoute(
      path: '/teknisi/report/:id',
      builder: (context, state) =>
          TeknisiReportDetailPage(reportId: state.pathParameters['id'] ?? '0'),
    ),
    GoRoute(
      path: '/teknisi/report/:id/complete',
      builder: (context, state) => TeknisiCompleteReportPage(
        reportId: state.pathParameters['id'] ?? '0',
      ),
    ),
    GoRoute(
      path: '/teknisi/map',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return TeknisiMapViewPage(
          latitude: extra['latitude'] ?? 0.0,
          longitude: extra['longitude'] ?? 0.0,
          locationName: extra['locationName'] ?? 'Lokasi Laporan',
        );
      },
    ),
    GoRoute(
      path: '/teknisi/settings',
      builder: (context, state) => const TeknisiSettingsPage(),
    ),
    GoRoute(
      path: '/teknisi/help',
      builder: (context, state) => const TeknisiHelpPage(),
    ),
    GoRoute(
      path: '/teknisi/setting',
      builder: (context, state) => const TeknisiSettingMainPage(),
    ),
    GoRoute(
      path: '/teknisi/edit-profile',
      builder: (context, state) => const TeknisiEditProfilePage(),
    ),
    GoRoute(
      path: '/teknisi/all-reports',
      builder: (context, state) {
        final status = state.uri.queryParameters['status'];
        final period = state.uri.queryParameters['period'];
        final emergency = state.uri.queryParameters['emergency'] == 'true';
        final assignedTo = state.uri.queryParameters['assignedTo'];
        return TeknisiAllReportsPage(
          initialStatus: status,
          initialPeriod: period,
          initialEmergency: emergency,
          assignedTo: assignedTo != null ? int.tryParse(assignedTo) : null,
        );
      },
    ),
    GoRoute(
      path: '/teknisi/siap-dimulai',
      builder: (context, state) => const TeknisiSiapDimulaiPage(),
    ),
    GoRoute(
      path: '/teknisi/sedang-dikerjakan',
      builder: (context, state) => const TeknisiSedangDikerjakanPage(),
    ),

    // ===============================================
    // PJ LOKASI ROUTES
    // ===============================================
    GoRoute(
      path: '/pj-gedung',
      builder: (context, state) => const PJGedungHomePage(),
    ),
    GoRoute(
      path: '/pj-gedung/reports',
      builder: (context, state) =>
          PJGedungReportsPage(queryParams: state.uri.queryParameters),
    ),
    GoRoute(
      path: '/pj-gedung/report/:id',
      builder: (context, state) =>
          PJGedungReportDetailPage(reportId: state.pathParameters['id'] ?? '0'),
    ),
    GoRoute(
      path: '/pj-gedung/statistics',
      builder: (context, state) {
        final locationName = state.uri.queryParameters['locationName'];
        return PJGedungStatisticsPage(locationName: locationName);
      },
    ),

    // ===============================================
    // SUPERVISOR ROUTES
    // ===============================================
    // Main supervisor shell with persistent bottom navigation
    GoRoute(
      path: '/supervisor',
      builder: (context, state) => const SupervisorShellPage(),
    ),
    // Detail page (opened on top of shell, has back button)
    GoRoute(
      path: '/supervisor/reports',
      builder: (context, state) =>
          SupervisorReportsPage(queryParams: state.uri.queryParameters),
    ),
    GoRoute(
      path: '/supervisor/statistics',
      builder: (context, state) => const SupervisorStatisticsPage(),
    ),
    // Filtered reports page with query parameters
    GoRoute(
      path: '/supervisor/reports/filter',
      builder: (context, state) =>
          SupervisorReportsPage(queryParams: state.uri.queryParameters),
    ),
    GoRoute(
      path: '/supervisor/review/:id',
      builder: (context, state) => SupervisorReviewPage(
        reportId: state.pathParameters['id'] ?? '0',
        extra: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/supervisor/archive',
      builder: (context, state) => const SupervisorArchivePage(),
    ),
    GoRoute(
      path: '/supervisor/setting',
      builder: (context, state) => const SupervisorSettingMainPage(),
    ),
    // Rejected reports review page
    GoRoute(
      path: '/supervisor/rejected',
      builder: (context, state) => const SupervisorRejectedReportsPage(),
    ),
    // Export Reports Page
    GoRoute(
      path: '/supervisor/non-gedung',
      builder: (context, state) => const SupervisorNonGedungPage(),
    ),
    GoRoute(
      path: '/supervisor/export',
      builder: (context, state) => const SupervisorExportPage(),
    ),
    GoRoute(
      path: '/supervisor/technicians',
      builder: (context, state) => const SupervisorTechnicianListPage(),
    ),
    GoRoute(
      path: '/supervisor/technician/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SupervisorTechnicianDetailPage(technicianId: id);
      },
    ),
    GoRoute(
      path: '/supervisor/technicians/add',
      builder: (context, state) => const SupervisorTechnicianFormPage(),
    ),
    GoRoute(
      path: '/supervisor/technicians/edit/:id',
      builder: (context, state) => SupervisorTechnicianFormPage(
        technicianId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/supervisor/pj-gedung/add',
      builder: (context, state) => const SupervisorPJGedungFormPage(),
    ),
    GoRoute(
      path: '/supervisor/pj-gedung/edit/:id',
      builder: (context, state) =>
          SupervisorPJGedungFormPage(pjGedungId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/supervisor/settings',
      builder: (context, state) => const SupervisorAccountSettingsPage(),
    ),
    GoRoute(
      path: '/supervisor/help',
      builder: (context, state) => const SupervisorHelpPage(),
    ),
    GoRoute(
      path: '/supervisor/categories',
      builder: (context, state) => const SupervisorCategoriesPage(),
    ),
    GoRoute(
      path: '/supervisor/activity-log',
      builder: (context, state) => const SupervisorActivityLogPage(),
    ),
    GoRoute(
      path: '/supervisor/locations',
      builder: (context, state) => const SupervisorLocationListPage(),
    ),
    GoRoute(
      path: '/supervisor/edit-profile',
      builder: (context, state) => const SupervisorEditProfilePage(),
    ),

    GoRoute(
      path: '/pj-gedung/history',
      builder: (context, state) {
        final filter = state.uri.queryParameters['filter'] ?? 'all';
        return PJGedungHistoryPage(initialFilter: filter);
      },
    ),
    GoRoute(
      path: '/pj-gedung/settings',
      builder: (context, state) => const PJGedungSettingsPage(),
    ),
    GoRoute(
      path: '/pj-gedung/help',
      builder: (context, state) => const PJGedungHelpPage(),
    ),
    GoRoute(
      path: '/pj-gedung/edit-profile',
      builder: (context, state) => const PJGedungEditProfilePage(),
    ),
    // ===============================================
    // ===============================================
    // ADMIN ROUTES
    // ===============================================
    // ADMIN SHELL
    ShellRoute(
      builder: (context, state, child) {
        return AdminShell(currentLocation: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'];
            final action = state.uri.queryParameters['action'];
            final initialIndex = tab != null ? int.tryParse(tab) ?? 0 : 0;
            return AdminUsersPage(initialIndex: initialIndex, action: action);
          },
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (context, state) => const AdminReportsPage(),
        ),
        GoRoute(
          path: '/admin/logs', // New Log Route
          builder: (context, state) => const AdminActivityLogPage(),
        ),
        GoRoute(
          path: '/admin/statistics', // New Statistics Route
          builder: (context, state) => const AdminStatisticsPage(),
        ),
        GoRoute(
          path: '/admin/profile',
          builder: (context, state) => const AdminProfilePage(),
        ),
      ],
    ),

    // Admin Support Pages (Outside Shell)
    GoRoute(
      path: '/admin/users/:id',
      builder: (context, state) {
        final userId = state.pathParameters['id']!;
        return UserDetailPage(userId: userId);
      },
    ),
    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const AdminSettingsPage(),
    ),
    GoRoute(
      path: '/admin/help',
      builder: (context, state) => const AdminHelpPage(),
    ),
    GoRoute(
      path: '/admin/reports/:id',
      builder: (context, state) {
        final reportId = state.pathParameters['id']!;
        return AdminReportDetailPage(reportId: reportId);
      },
    ),

    // Admin pages outside shell (focused views without bottom nav)
  ],
);
