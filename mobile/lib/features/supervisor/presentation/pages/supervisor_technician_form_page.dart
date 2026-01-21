import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class SupervisorTechnicianFormPage extends StatefulWidget {
  final String? technicianId; // If null, creating new technician

  const SupervisorTechnicianFormPage({super.key, this.technicianId});

  @override
  State<SupervisorTechnicianFormPage> createState() =>
      _SupervisorTechnicianFormPageState();
}

class _SupervisorTechnicianFormPageState
    extends State<SupervisorTechnicianFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Teknisi Listrik';
  bool _isLoading = false;

  final List<String> _roles = [
    'Teknisi Listrik',
    'Teknisi Sipil',
    'Teknisi AC',
    'Teknisi Jaringan',
    'Teknisi Plumbing',
  ];

  bool get isEditing => widget.technicianId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadTechnicianData();
    }
  }

  void _loadTechnicianData() {
    // TODO: [BACKEND] Fetch technician data by ID
    setState(() {
      _nameController.text = 'Budi Santoso';
      _emailController.text = 'budi.santoso@staff.undip.ac.id';
      _phoneController.text = '081234567890';
      _selectedRole = 'Teknisi Listrik';
    });
  }

  void _saveTechnician() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // TODO: [BACKEND] API Call to Create/Update Technician
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Data teknisi berhasil diperbarui'
                    : 'Teknisi baru berhasil ditambahkan',
              ),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Return true to refresh list
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Teknisi' : 'Tambah Teknisi'),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informasi Pribadi'),
              const Gap(16),
              _buildTextField(
                label: 'Nama Lengkap',
                controller: _nameController,
                icon: LucideIcons.user,
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const Gap(16),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    !v!.contains('@') ? 'Email tidak valid' : null,
              ),
              const Gap(16),
              _buildTextField(
                label: 'Nomor Telepon',
                controller: _phoneController,
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v!.isEmpty ? 'Nomor telepon wajib diisi' : null,
              ),
              const Gap(24),
              _buildSectionTitle('Peran & Akses'),
              const Gap(16),
              _buildDropdownField(),
              const Gap(16),
              if (!isEditing) // Only show password field for new users
                _buildTextField(
                  label: 'Password Default',
                  controller: _passwordController,
                  icon: LucideIcons.lock,
                  isPassword: true,
                  validator: (v) =>
                      v!.length < 6 ? 'Password minimal 6 karakter' : null,
                ),
              if (isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      const Gap(12),
                      const Expanded(
                        child: Text(
                          'Password tidak ditampilkan untuk keamanan. Reset password jika diperlukan.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTechnician,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.supervisorColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'Simpan Perubahan' : 'Tambah Teknisi',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.supervisorColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Spesialisasi',
        prefixIcon: const Icon(LucideIcons.wrench, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _roles
          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
          .toList(),
      onChanged: (value) => setState(() => _selectedRole = value!),
    );
  }
}
