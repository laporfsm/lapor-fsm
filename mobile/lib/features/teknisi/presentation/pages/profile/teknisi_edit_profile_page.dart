import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/auth_service.dart';

class TeknisiEditProfilePage extends StatefulWidget {
  const TeknisiEditProfilePage({super.key});

  @override
  State<TeknisiEditProfilePage> createState() => _TeknisiEditProfilePageState();
}

class _TeknisiEditProfilePageState extends State<TeknisiEditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers - Editable fields only
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isInitializing = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await authService.getCurrentUser();
    if (mounted) {
      if (user != null) {
        _userId = user['id'];
        _phoneController.text = user['phone'] ?? '';
        _addressController.text = user['address'] ?? '';
      }
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) return;

    setState(() => _isLoading = true);

    // TODO: [BACKEND] Support address update. Currently reusing registerPhone for phone update.
    final success = await authService.registerPhone(
      userId: _userId!, 
      phone: _phoneController.text
    );
    
    // Note: We might need a proper updateProfile endpoint in backend for address

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
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
                    LucideIcons.wrench,
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
                    // TODO: [BACKEND] Get from logged in user
                    _ReadOnlyField(
                      label: 'Nama Lengkap',
                      value: 'Budi Teknisi',
                      icon: LucideIcons.user,
                    ),
                    const Gap(12),
                    _ReadOnlyField(
                      label: 'Email',
                      value: 'budi.teknisi@undip.ac.id',
                      icon: LucideIcons.mail,
                    ),
                    const Gap(12),
                    _ReadOnlyField(
                      label: 'NIP',
                      value: '198501152010011001',
                      icon: LucideIcons.hash,
                    ),
                    const Gap(12),
                    _ReadOnlyField(
                      label: 'Departemen',
                      value: 'Unit Pemeliharaan',
                      icon: LucideIcons.building,
                    ),
                    const Gap(12),
                    _ReadOnlyField(
                      label: 'Spesialisasi',
                      value: 'Kelistrikan & AC',
                      icon: LucideIcons.wrench,
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
