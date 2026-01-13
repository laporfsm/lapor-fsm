import 'package:go_router/go_router.dart';
import 'package:mobile/features/pelapor/presentation/pages/auth/login_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/auth/complete_profile_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/home_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/create_report_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/report_success_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/report/report_detail_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/feed/public_feed_page.dart';
import 'package:mobile/features/pelapor/presentation/pages/history/report_history_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login', // Start with login for demo
  routes: [
    // Auth
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfilePage(),
    ),
    
    // Main
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    
    // Report Flow
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
      builder: (context, state) => ReportDetailPage(
        reportId: state.pathParameters['id'] ?? '0',
      ),
    ),
    
    // Feed & History
    GoRoute(
      path: '/feed',
      builder: (context, state) => const PublicFeedPage(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const ReportHistoryPage(),
    ),
  ],
);
