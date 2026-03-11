import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Artificial delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isLoggedIn = await authService.isLoggedIn();

    if (!mounted) return;

    if (!isLoggedIn) {
      context.go('/login');
      return;
    }

    final user = await authService.getCurrentUser();
    final role = user?['role'];

    if (!mounted) return;

    if (role == 'teknisi') {
      context.go('/teknisi');
    } else if (role == 'supervisor') {
      context.go('/supervisor');
    } else if (role == 'pj_gedung') {
      context.go('/pj-gedung');
    } else if (role == 'admin') {
      context.go('/admin/dashboard');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/Lapor FSM! Logo Polos.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      size: 60,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const Gap(32),
            // Title
            const Text(
              'Lapor FSM!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
                letterSpacing: -1,
              ),
            ),
            const Gap(12),
            // Description
            Text(
              'Sistem Pelaporan Fasilitas\nFakultas Sains & Matematika',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(48),
            // Loading Indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
