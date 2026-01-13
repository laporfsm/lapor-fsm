import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // Simulate save
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/'); // Go to Home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Lengkapi Profil"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.userCheck, size: 48, color: AppTheme.primaryColor),
                const Gap(16),
                const Text(
                  "Satu Langkah Lagi!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Gap(8),
                const Text(
                  "Masukkan nomor WhatsApp/HP aktif Anda untuk keperluan koordinasi lapangan.",
                  style: TextStyle(color: Colors.grey),
                ),
                const Gap(32),
                
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Nomor WhatsApp/HP",
                    hintText: "08123456789",
                    prefixIcon: Icon(LucideIcons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Nomor HP wajib diisi";
                    }
                    if (value.length < 10) {
                      return "Nomor HP tidak valid";
                    }
                    return null;
                  },
                ),
                
                const Spacer(),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SIMPAN & LANJUTKAN"),
                  ),
                ),
                const Gap(16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
