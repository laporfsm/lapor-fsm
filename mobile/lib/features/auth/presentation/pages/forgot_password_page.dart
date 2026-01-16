import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

/// Forgot Password Page
/// Flow:
/// 1. User memasukkan email
/// 2. Sistem mengirimkan link reset password ke email
/// 3. User klik link dan diarahkan ke halaman reset password
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Integrate with backend API to send reset password email
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim link reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _resendEmail() {
    setState(() => _emailSent = false);
    _handleSendResetLink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Lupa Password'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildEmailSentView() : _buildEmailForm(),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Gap(40),

          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.keyRound,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const Gap(32),

          // Title
          const Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(12),
          Text(
            'Masukkan email yang terdaftar. Kami akan mengirimkan link untuk mereset password Anda.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(40),

          // Email Field
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Gap(8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Masukkan email Anda',
              prefixIcon: const Icon(LucideIcons.mail),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email wajib diisi';
              }
              if (!value.contains('@')) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const Gap(32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendResetLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Kirim Link Reset',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const Gap(24),

          // Back to Login
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              'Kembali ke Login',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Gap(60),

        // Success Icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.mailCheck,
            size: 48,
            color: Colors.green,
          ),
        ),
        const Gap(32),

        // Title
        const Text(
          'Email Terkirim!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(12),
        Text(
          'Kami telah mengirimkan link reset password ke:',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.mail, size: 16, color: Colors.grey.shade600),
              const Gap(8),
              Text(
                _emailController.text,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const Gap(24),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.info, color: Colors.blue.shade700, size: 18),
                  const Gap(8),
                  Text(
                    'Petunjuk:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const Gap(8),
              _buildInstructionItem('1', 'Buka email Anda'),
              _buildInstructionItem('2', 'Cari email dari Lapor FSM'),
              _buildInstructionItem('3', 'Klik link reset password'),
              _buildInstructionItem('4', 'Buat password baru'),
            ],
          ),
        ),
        const Gap(16),

        // Spam warning
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.alertTriangle,
                  color: Colors.orange.shade700, size: 18),
              const Gap(8),
              Expanded(
                child: Text(
                  'Tidak menerima email? Cek folder spam atau junk.',
                  style:
                      TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const Gap(32),

        // Resend Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _resendEmail,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Kirim Ulang Email'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const Gap(16),

        // Back to Login
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Kembali ke Login'),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          const Gap(8),
          Text(
            text,
            style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
