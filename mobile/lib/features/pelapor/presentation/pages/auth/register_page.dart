import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/core/services/auth_service.dart';

/// Registration Page with email validation
/// - If email is *.undip.ac.id -> proceed directly
/// - If email is NOT *.undip.ac.id -> require ID card upload
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nimNipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0; // 0 = email, 1 = ID card (if needed), 2 = user data
  bool _requiresIdCard = false;
  XFile? _idCardImage;
  Uint8List? _idCardBytes; // For web compatibility

  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _nimNipController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  bool _isUndipEmail(String email) {
    final lowerEmail = email.toLowerCase();
    return lowerEmail.endsWith('@undip.ac.id') ||
        lowerEmail.endsWith('@students.undip.ac.id') ||
        lowerEmail.endsWith('@live.undip.ac.id') ||
        lowerEmail.endsWith('@lecturer.undip.ac.id') ||
        lowerEmail.endsWith('@staff.undip.ac.id');
  }

  void _validateEmail() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _requiresIdCard = !_isUndipEmail(_emailController.text);
      _currentStep = _requiresIdCard ? 1 : 2;
    });
  }

  Future<void> _pickIdCard() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Sumber Gambar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: LucideIcons.camera,
                    label: 'Kamera',
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _idCardImage = image;
                          _idCardBytes = bytes;
                        });
                      }
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: LucideIcons.image,
                    label: 'Galeri',
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _idCardImage = image;
                          _idCardBytes = bytes;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const Gap(12),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const Gap(8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _proceedToUserData() {
    if (_requiresIdCard && _idCardBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kartu identitas wajib diunggah'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _currentStep = 2);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        nimNip: _nimNipController.text,
        department: 'Sains dan Matematika', // Default or from form if added
        address: _addressController.text,
        emergencyName: _emergencyNameController.text,
        emergencyPhone: _emergencyPhoneController.text,
      );

      if (mounted) {
        if (result['success']) {
          if (result['needsApproval'] == true) {
            _showPendingApprovalDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registrasi berhasil! Silakan login.'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/login');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registrasi gagal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrasi gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPendingApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.clock, size: 48, color: Colors.orange),
            ),
            const Gap(20),
            const Text(
              'Menunggu Verifikasi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Gap(12),
            Text(
              'Akun Anda sedang dalam proses verifikasi oleh Admin. '
              'Anda akan menerima notifikasi setelah akun diaktifkan.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali ke Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                if (_currentStep == 2 && _requiresIdCard) {
                  _currentStep = 1;
                } else {
                  _currentStep = 0;
                }
              });
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              _buildProgressIndicator(),
              const Gap(20),

              // Step Content
              if (_currentStep == 0) _buildEmailStep(),
              if (_currentStep == 1) _buildIdCardStep(),
              if (_currentStep == 2) _buildUserDataStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStepCircle(0, 'Email'),
        Expanded(child: Container(height: 2, color: _currentStep >= 1 ? AppTheme.primaryColor : Colors.grey.shade300)),
        if (_requiresIdCard) ...[
          _buildStepCircle(1, 'ID'),
          Expanded(child: Container(height: 2, color: _currentStep >= 2 ? AppTheme.primaryColor : Colors.grey.shade300)),
        ],
        _buildStepCircle(_requiresIdCard ? 2 : 1, 'Data'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masukkan Email',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        Text(
          'Email UNDIP akan langsung terverifikasi. Email lain memerlukan upload kartu identitas.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const Gap(24),

        const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
        const Gap(8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'contoh@students.undip.ac.id',
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
          ),
        ),
        const Gap(24),

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, color: Colors.blue.shade700),
              const Gap(12),
              Expanded(
                child: Text(
                  'Email UNDIP yang valid:\n• @undip.ac.id\n• @students.undip.ac.id\n• @live.undip.ac.id',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const Gap(32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _validateEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lanjutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildIdCardStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Kartu Identitas',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        Text(
          'Upload kartu identitas (KTP/KTM/SIM) untuk verifikasi akun.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const Gap(20),

        // Warning box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: Colors.orange.shade700),
              const Gap(12),
              Expanded(
                child: Text(
                  'Akun Anda akan menunggu verifikasi admin sebelum bisa digunakan.',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const Gap(24),

        // ID Card Upload
        const Text('Kartu Identitas *', style: TextStyle(fontWeight: FontWeight.w600)),
        const Gap(8),
        GestureDetector(
          onTap: _pickIdCard,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _idCardBytes != null ? AppTheme.primaryColor : Colors.grey.shade300,
                width: _idCardBytes != null ? 2 : 1,
              ),
            ),
            child: _idCardBytes != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.memory(
                          _idCardBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _idCardImage = null;
                            _idCardBytes = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.creditCard, size: 48, color: Colors.grey.shade400),
                      const Gap(12),
                      Text(
                        'Tap untuk upload kartu identitas',
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(4),
                      Text(
                        'KTP / KTM / SIM',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
        const Gap(32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _proceedToUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lanjutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDataStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lengkapi Data Diri',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Gap(6),
          Text(
            'Isi data berikut untuk menyelesaikan pendaftaran.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const Gap(20),

          // Email (read-only)
          const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.mail, color: Colors.grey.shade500, size: 20),
                const Gap(10),
                Expanded(
                  child: Text(
                    _emailController.text,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isUndipEmail(_emailController.text))
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('UNDIP', style: TextStyle(color: Colors.green.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const Gap(20),

          // Name
          const Text('Nama Lengkap *', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration('Masukkan nama lengkap', LucideIcons.user),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nama wajib diisi';
              return null;
            },
          ),
          const Gap(20),

          // NIM/NIP
          const Text('NIM / NIP *', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          TextFormField(
            controller: _nimNipController,
            decoration: _inputDecoration('Masukkan NIM atau NIP', LucideIcons.hash),
            validator: (value) {
              if (value == null || value.isEmpty) return 'NIM/NIP wajib diisi';
              return null;
            },
          ),
          const Gap(20),

          // Phone
          const Text('Nomor HP *', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('08xxxxxxxxxx', LucideIcons.phone),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nomor HP wajib diisi';
              return null;
            },
          ),
          const Gap(20),

          // Address
          const Text('Alamat', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: _inputDecoration('Masukkan alamat domisili', LucideIcons.mapPin),
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
                Icon(LucideIcons.alertCircle, color: Colors.red.shade700, size: 20),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Kontak darurat akan dihubungi jika terjadi situasi mendesak',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),

          // Emergency Contact Name
          const Text('Nama Kontak Darurat *', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          TextFormField(
            controller: _emergencyNameController,
            decoration: _inputDecoration('Nama orang yang bisa dihubungi', LucideIcons.userCircle),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nama kontak darurat wajib diisi';
              return null;
            },
          ),
          const Gap(20),

          // Emergency Contact Phone
          const Text('Nomor Kontak Darurat *', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          TextFormField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('08xxxxxxxxxx', LucideIcons.phoneCall),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nomor kontak darurat wajib diisi';
              return null;
            },
          ),
          const Gap(20),

          // Password
          const Text('Password *', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Minimal 6 karakter',
              prefixIcon: const Icon(LucideIcons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password wajib diisi';
              if (value.length < 6) return 'Password minimal 6 karakter';
              return null;
            },
          ),
          const Gap(20),

          // Confirm Password
          const Text('Konfirmasi Password *', style: TextStyle(fontWeight: FontWeight.w600)),
          const Gap(8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Ulangi password',
              prefixIcon: const Icon(LucideIcons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Konfirmasi password wajib diisi';
              if (value != _passwordController.text) return 'Password tidak cocok';
              return null;
            },
          ),
          const Gap(32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const Gap(32),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
    );
  }
}
