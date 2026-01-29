import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/pelapor/presentation/pages/auth/login_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/auth/register_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/auth/complete_profile_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/home_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/create_report_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/report_success_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/report_detail_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/feed/public_feed_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/history/report_history_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/profile/profile_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/profile/edit_profile_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/profile/settings_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/profile/help_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/emergency_report_page.dart';

// Teknisi imports
import 'package:mobile/features/teknisi/presentation/pages/dashboard/teknisi_home_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_report_detail_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_complete_report_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_map_view_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/profile/teknisi_settings_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/profile/teknisi_help_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/profile/teknisi_edit_profile_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/profile/teknisi_profile_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/reports/teknisi_all_reports_page.dart';

// PJ Gedung imports
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_main_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_history_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_reports_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_report_detail_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_statistics_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_help_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_settings_page.dart';

// Supervisor imports
import 'package:mobile/features/supervisor/presentation/pages/dashboard/supervisor_shell_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_reports_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_review_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_archive_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_rejected_reports_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/reports/supervisor_export_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_technician_list_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_technician_detail_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_statistics_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_technician_form_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/profile/supervisor_settings_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/profile/supervisor_help_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/profile/supervisor_profile_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_categories_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_activity_log_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/management/supervisor_building_list_page.dart';

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
import 'package:mobile/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:mobile/features/notification/presentation/pages/notification_page.dart';

// Navigation key for ShellRoute
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/login', // Start with login for demo
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
      path: '/notifications',
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),

    // ===============================================
    // PELAPOR SHELL ROUTE - Persistent Bottom Nav
    // ===============================================
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        // Determine current index from location
        int currentIndex = 0;
        final location = state.uri.path;
        if (location == '/') {
          currentIndex = 0;
        } else if (location == '/feed') {
          currentIndex = 1;
        } else if (location == '/history') {
          currentIndex = 2;
        } else if (location.startsWith('/profile')) {
          currentIndex = 3;
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                  break;
                case 1:
                  context.go('/feed');
                  break;
                case 2:
                  context.go('/history');
                  break;
                case 3:
                  context.go('/profile');
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.home),
                label: "Beranda",
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.newspaper),
                label: "Feed",
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.fileText),
                label: "Riwayat",
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.user),
                label: "Profil",
              ),
            ],
          ),
        );
      },
      routes: [
        // Main - Pelapor (inside shell)
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        // Feed & History - Pelapor (inside shell)
        GoRoute(
          path: '/feed',
          builder: (context, state) => const PublicFeedPage(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const ReportHistoryPage(),
        ),
        // Profile - Pelapor (inside shell)
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),

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
      path: '/teknisi/profile',
      builder: (context, state) => const TeknisiProfilePage(),
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
      path: '/teknisi/edit-profile',
      builder: (context, state) => const TeknisiEditProfilePage(),
    ),
    GoRoute(
      path: '/teknisi/all-reports',
      builder: (context, state) {
        final status = state.uri.queryParameters['status'];
        final period = state.uri.queryParameters['period'];
        final emergency = state.uri.queryParameters['emergency'] == 'true';
        return TeknisiAllReportsPage(
          initialStatus: status,
          initialPeriod: period,
          initialEmergency: emergency,
        );
      },
    ),

    // ===============================================
    // PJ GEDUNG ROUTES
    // ===============================================
    GoRoute(
      path: '/pj-gedung',
      builder: (context, state) => const PJGedungMainPage(),
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
        final buildingName = state.uri.queryParameters['buildingName'];
        return PJGedungStatisticsPage(buildingName: buildingName);
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
      path: '/supervisor/profile',
      builder: (context, state) => const SupervisorProfilePage(),
    ),
    // Rejected reports review page
    GoRoute(
      path: '/supervisor/rejected',
      builder: (context, state) => const SupervisorRejectedReportsPage(),
    ),
    // Export Reports Page
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
      path: '/supervisor/settings',
      builder: (context, state) => const SupervisorSettingsPage(),
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
      path: '/supervisor/buildings',
      builder: (context, state) => const SupervisorBuildingListPage(),
    ),

    GoRoute(
      path: '/pj-gedung/history',
      builder: (context, state) {
        final filter = state.uri.queryParameters['filter'] ?? 'pending';
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
