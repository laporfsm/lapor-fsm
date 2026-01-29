import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers - Editable fields only
  final _phoneController = TextEditingController(text: '081234567890');
  final _addressController = TextEditingController(text: 'Tembalang, Semarang');
  final _emergencyNameController = TextEditingController(text: 'Budi Santoso');
  final _emergencyPhoneController = TextEditingController(text: '081298765432');

  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate save
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'SIMPAN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section (non-editable)
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    border: Border.all(color: AppTheme.primaryColor, width: 3),
                  ),
                  child: const Icon(
                    LucideIcons.user,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const Gap(24),

              // Read-only Data Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.lock,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const Gap(8),
                        Text(
                          'Data Akun (tidak dapat diubah)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    _ReadOnlyField(
                      label: 'Nama Lengkap',
                      value: 'Sulhan Fuadi',
                      icon: LucideIcons.user,
                    ),
                    const Gap(12),
                    _ReadOnlyField(
                      label: 'Email',
                      value: 'sulhan.fuadi@students.undip.ac.id',
                      icon: LucideIcons.mail,
                    ),
                    const Gap(12),
                    _ReadOnlyField(
                      label: 'NIM/NIP',
                      value: '24060123130115',
                      icon: LucideIcons.hash,
                    ),
                  ],
                ),
              ),
              const Gap(24),

              // Editable Fields Header
              const Text(
                'Informasi Kontak',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Gap(4),
              Text(
                'Data berikut dapat Anda perbarui',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Gap(16),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP *',
                  hintText: '08xxxxxxxxxx',
                  prefixIcon: Icon(LucideIcons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor HP wajib diisi';
                  }
                  if (value.length < 10) return 'Nomor HP tidak valid';
                  return null;
                },
              ),
              const Gap(16),

              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  hintText: 'Alamat domisili',
                  prefixIcon: Icon(LucideIcons.mapPin),
                ),
              ),
              const Gap(24),

              // Emergency Contact Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'Kontak darurat akan dihubungi jika terjadi situasi mendesak',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Emergency Contact Name
              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kontak Darurat *',
                  hintText: 'Nama orang yang bisa dihubungi',
                  prefixIcon: Icon(LucideIcons.userCircle),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama kontak darurat wajib diisi';
                  }
                  return null;
                },
              ),
              const Gap(16),

              // Emergency Contact Phone
              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Kontak Darurat *',
                  hintText: '08xxxxxxxxxx',
                  prefixIcon: Icon(LucideIcons.phoneCall),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor kontak darurat wajib diisi';
                  }
                  return null;
                },
              ),
              const Gap(32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(LucideIcons.save),
                  label: Text(_isLoading ? 'Menyimpan...' : 'SIMPAN PERUBAHAN'),
                ),
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const Gap(2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
