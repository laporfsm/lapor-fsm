import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
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
// Staff Profile (shared)
import 'package:mobile/features/auth/presentation/pages/staff_profile_page.dart';
// Teknisi imports
import 'package:mobile/features/teknisi/presentation/pages/teknisi_home_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_report_detail_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_complete_report_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_map_view_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_settings_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_help_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_edit_profile_page.dart';
// Supervisor imports
import 'package:mobile/features/supervisor/presentation/pages/supervisor_shell_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_reports_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_review_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_archive_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_reports_list_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_rejected_reports_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_export_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_technician_list_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_technician_detail_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_statistics_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_technician_form_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_settings_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_help_page.dart';
// Admin imports
import 'package:mobile/features/admin/presentation/pages/admin_home_page.dart';
import 'package:mobile/features/admin/presentation/pages/admin_staff_page.dart';
import 'package:mobile/features/admin/presentation/pages/admin_categories_page.dart';
import 'package:mobile/features/admin/presentation/pages/admin_users_page.dart';
import 'package:mobile/features/admin/presentation/pages/admin_pending_registrations_page.dart';
import 'package:mobile/features/admin/presentation/pages/admin_notifications_page.dart';
import 'package:mobile/features/admin/presentation/pages/admin_profile_page.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_shell.dart';
// Auth imports
import 'package:mobile/features/auth/presentation/pages/forgot_password_page.dart';

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
                label: "Aktivitas",
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
      builder: (context, state) => const StaffProfilePage(role: 'teknisi'),
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
      builder: (context, state) => const SupervisorReportsPage(),
    ),
    GoRoute(
      path: '/supervisor/statistics',
      builder: (context, state) => const SupervisorStatisticsPage(),
    ),
    // Filtered reports page with query parameters
    GoRoute(
      path: '/supervisor/reports/filter',
      builder: (context, state) {
        final status = state.uri.queryParameters['status'];
        final period = state.uri.queryParameters['period'];
        final emergency = state.uri.queryParameters['emergency'] == 'true';
        return SupervisorReportsListPage(
          initialStatus: status,
          initialPeriod: period,
          showEmergencyOnly: emergency,
        );
      },
    ),
    GoRoute(
      path: '/supervisor/review/:id',
      builder: (context, state) =>
          SupervisorReviewPage(reportId: state.pathParameters['id'] ?? '0'),
    ),
    GoRoute(
      path: '/supervisor/archive',
      builder: (context, state) => const SupervisorArchivePage(),
    ),
    GoRoute(
      path: '/supervisor/profile',
      builder: (context, state) => const StaffProfilePage(role: 'supervisor'),
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

    // ===============================================
    // ADMIN SHELL ROUTE - Persistent Bottom Nav
    // ===============================================
    ShellRoute(
      navigatorKey: GlobalKey<NavigatorState>(),
      builder: (context, state, child) {
        return AdminShell(currentLocation: state.uri.path, child: child);
      },
      routes: [
        // Bottom Nav Tabs
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminHomePage(),
        ),
        GoRoute(
          path: '/admin/verifikasi',
          builder: (context, state) => const AdminPendingRegistrationsPage(),
        ),
        GoRoute(
          path: '/admin/notifikasi',
          builder: (context, state) => const AdminNotificationsPage(),
        ),
        GoRoute(
          path: '/admin/profil',
          builder: (context, state) => const AdminProfilePage(),
        ),
        // Pages accessed from Beranda (with bottom nav visible)
        GoRoute(
          path: '/admin/staff',
          builder: (context, state) => const AdminStaffPage(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersPage(),
        ),
        GoRoute(
          path: '/admin/categories',
          builder: (context, state) => const AdminCategoriesPage(),
        ),
      ],
    ),

    // Admin pages outside shell (focused views without bottom nav)
  ],
);
