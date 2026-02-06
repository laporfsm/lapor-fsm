import 'package:flutter/material.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';

import 'package:mobile/features/supervisor/data/services/supervisor_staff_service.dart';

class SupervisorTechnicianFormPage extends StatefulWidget {
  final String? technicianId; // If null, creating new technician

  const SupervisorTechnicianFormPage({super.key, this.technicianId});

  @override
  State<SupervisorTechnicianFormPage> createState() =>
      _SupervisorTechnicianFormPageState();
}

class _SupervisorTechnicianFormPageState
    extends State<SupervisorTechnicianFormPage> {
  // Service
  final _supervisorStaffService = SupervisorStaffService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;
  bool _isLoading = false;
  List<String> _roles = [];

  bool get isEditing => widget.technicianId != null;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _fetchRoles();
    if (isEditing) {
      _loadTechnicianData();
    }
  }

  Future<void> _fetchRoles() async {
    setState(() => _isLoading = true);
    final data = await reportService.getSpecializations();
    if (mounted) {
      setState(() {
        _roles = data.map((e) => e['name'].toString()).toList();
        if (_roles.isNotEmpty && _selectedRole == null) {
          _selectedRole = _roles.first;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTechnicianData() async {
    setState(() => _isLoading = true);
    try {
      final technician = await _supervisorStaffService.getTechnicianDetail(
        widget.technicianId!,
      );
      if (mounted && technician != null) {
        setState(() {
          _nameController.text = technician['name'] ?? '';
          _emailController.text = technician['email'] ?? '';
          _phoneController.text = technician['phone'] ?? '';
          _addressController.text = technician['address'] ?? '';

          // Map backend 'specialization' to UI dropdown
          // Note: technician['role'] is the system role ('teknisi'),
          // while 'specialization' contains 'Teknisi Listrik', etc.
          final spec = technician['specialization'] as String?;
          if (spec != null && _roles.contains(spec)) {
            _selectedRole = spec;
          }
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data teknisi')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _saveTechnician() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final data = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'specialization': _selectedRole, // Correct key for backend
      };

      if (!isEditing) {
        // Add password for new technician
        data['password'] = _passwordController.text;
      }

      bool success;
      if (isEditing) {
        success = await _supervisorStaffService.updateTechnician(
          widget.technicianId!,
          data,
        );
      } else {
        success = await _supervisorStaffService.createTechnician(data);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Nomor telepon wajib diisi';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                    return 'Hanya boleh angka';
                  }
                  if (v.length < 10) return 'Minimal 10 digit';
                  if (v.length > 15) return 'Maksimal 15 digit';
                  return null;
                },
              ),
              const Gap(16),
              _buildTextField(
                label: 'Alamat',
                controller: _addressController,
                icon: LucideIcons.mapPin,
                validator: (v) => null, // Optional
                minLines: 2,
                maxLines: 4,
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
    int? minLines,
    int? maxLines,
  }) {
    // Only technician itself can edit their personal info.
    // Supervisor can only edit specialization or delete.
    // So if isEditing is true, we disable these fields.
    // Exception: Password field is hidden in edit mode anyway.
    final bool isReadOnly = isEditing && !isPassword;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      validator: validator,
      minLines: minLines ?? 1,
      maxLines: maxLines ?? 1,
      readOnly: isReadOnly,
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
        fillColor: isReadOnly ? Colors.grey.shade100 : Colors.white,
      ),
    );
  }

  Widget _buildDropdownField() {
    if (_roles.isEmpty && _isLoading) {
      return const Center(child: LinearProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
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
      validator: (v) => v == null ? 'Pilih spesialisasi' : null,
    );
  }
}
