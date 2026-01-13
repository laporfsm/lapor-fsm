import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleSSOLogin() async {
    setState(() => _isLoading = true);
    
    // Simulate SSO login delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isLoading = false);
      // Check if first time (no phone number) -> go to complete profile
      // For now, simulate first time user
      context.go('/complete-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // Logo & Title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.megaphone,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Gap(24),
              const Text(
                "Lapor FSM!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Gap(8),
              const Text(
                "Sistem Pelaporan Insiden & Fasilitas\nFakultas Sains dan Matematika",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              
              // SSO Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSSOLogin,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.logIn),
                  label: Text(_isLoading ? "Menghubungkan..." : "Login dengan SSO Undip"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const Gap(16),
              Text(
                "Gunakan akun SSO Undip Anda untuk masuk",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }
}
