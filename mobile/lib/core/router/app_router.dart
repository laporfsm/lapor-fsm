import 'package:go_router/go_router.dart';
import 'package:mobile/features/pelapor/presentation/pages/auth/login_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/auth/complete_profile_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/home_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/create_report_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/report_success_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/report_detail_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/feed/public_feed_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/history/report_history_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/profile/profile_page.dart';
// Staff & Teknisi imports
import 'package:mobile/features/auth/presentation/pages/staff_login_page.dart';
import 'package:mobile/features/auth/presentation/pages/staff_profile_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_home_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_report_detail_page.dart';
import 'package:mobile/features/teknisi/presentation/pages/teknisi_complete_report_page.dart';
// Supervisor imports
import 'package:mobile/features/supervisor/presentation/pages/supervisor_home_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_reports_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_review_page.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_archive_page.dart';
// Admin imports
import 'package:mobile/features/admin/presentation/pages/admin_home_page.dart';
import 'package:mobile/features/admin/presentation/pages/admin_staff_page.dart';
import 'package:mobile/features/admin/presentation/pages/admin_categories_page.dart';
import 'package:mobile/features/admin/presentation/pages/admin_users_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login', // Start with login for demo
  routes: [
    // Auth - Pelapor
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfilePage(),
    ),

    // Auth - Staff (Teknisi, Supervisor, Admin)
    GoRoute(
      path: '/staff-login',
      builder: (context, state) => const StaffLoginPage(),
    ),

    // Main - Pelapor
    GoRoute(path: '/', builder: (context, state) => const HomePage()),

    // Report Flow - Pelapor
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

    // Feed & History - Pelapor
    GoRoute(path: '/feed', builder: (context, state) => const PublicFeedPage()),
    GoRoute(
      path: '/history',
      builder: (context, state) => const ReportHistoryPage(),
    ),

    // Profile - Pelapor
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),

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

    // ===============================================
    // SUPERVISOR ROUTES
    // ===============================================
    GoRoute(
      path: '/supervisor',
      builder: (context, state) => const SupervisorHomePage(),
    ),
    GoRoute(
      path: '/supervisor/reports',
      builder: (context, state) => const SupervisorReportsPage(),
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

    // ===============================================
    // ADMIN ROUTES
    // ===============================================
    GoRoute(path: '/admin', builder: (context, state) => const AdminHomePage()),
    GoRoute(
      path: '/admin/staff',
      builder: (context, state) => const AdminStaffPage(),
    ),
    GoRoute(
      path: '/admin/categories',
      builder: (context, state) => const AdminCategoriesPage(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUsersPage(),
    ),
    GoRoute(
      path: '/admin/profile',
      builder: (context, state) => const StaffProfilePage(role: 'admin'),
    ),
  ],
);
