import 'package:flutter/material.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/data/services/supervisor_staff_service.dart';

class SupervisorPJGedungFormPage extends StatefulWidget {
  final String? pjGedungId; // If null, creating new PJ Gedung

  const SupervisorPJGedungFormPage({super.key, this.pjGedungId});

  @override
  State<SupervisorPJGedungFormPage> createState() =>
      _SupervisorPJGedungFormPageState();
}

class _SupervisorPJGedungFormPageState
    extends State<SupervisorPJGedungFormPage> {
  final _supervisorStaffService = SupervisorStaffService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedLocation;
  bool _isLoading = false;
  List<String> _buildings = [];

  bool get isEditing => widget.pjGedungId != null;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _fetchLocations();
    if (isEditing) {
      _loadPJGedungData();
    }
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);
    try {
      final data = await reportService.getLocations();
      if (mounted) {
        setState(() {
          _buildings = data.map((e) => e['name'].toString()).toList();
          if (_buildings.isNotEmpty &&
              _selectedLocation == null &&
              !isEditing) {
            _selectedLocation = _buildings.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPJGedungData() async {
    setState(() => _isLoading = true);
    try {
      final pj = await _supervisorStaffService.getPJGedungDetail(
        widget.pjGedungId!,
      );
      if (mounted && pj != null) {
        setState(() {
          _nameController.text = pj['name'] ?? '';
          _emailController.text = pj['email'] ?? '';
          _phoneController.text = pj['phone'] ?? '';

          final managedBy = pj['managedLocation'] as String?;
          if (managedBy != null && _buildings.contains(managedBy)) {
            _selectedLocation = managedBy;
          }
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data PJ Gedung')),
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

  Future<void> _savePJGedung() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final data = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'managedLocation': _selectedLocation,
      };

      if (!isEditing) {
        data['password'] = _passwordController.text;
      }

      bool success;
      if (isEditing) {
        success = await _supervisorStaffService.updatePJGedung(
          widget.pjGedungId!,
          data,
        );
      } else {
        success = await _supervisorStaffService.createPJGedung(data);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Data PJ Gedung berhasil diperbarui'
                    : 'PJ Gedung baru berhasil ditambahkan',
              ),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
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
        title: Text(isEditing ? 'Edit PJ Gedung' : 'Tambah PJ Gedung'),
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
      body: _isLoading && _buildings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        return null;
                      },
                    ),
                    const Gap(24),
                    _buildSectionTitle('Lokasi yang Dikelola'),
                    const Gap(16),
                    _buildDropdownField(),
                    const Gap(16),
                    if (!isEditing)
                      _buildTextField(
                        label: 'Password Default',
                        controller: _passwordController,
                        icon: LucideIcons.lock,
                        isPassword: true,
                        validator: (v) => v!.length < 6
                            ? 'Password minimal 6 karakter'
                            : null,
                      ),
                    const Gap(32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePJGedung,
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
                                isEditing
                                    ? 'Simpan Perubahan'
                                    : 'Tambah PJ Gedung',
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
      initialValue: _selectedLocation,
      decoration: InputDecoration(
        labelText: 'Pilih Lokasi',
        prefixIcon: const Icon(LucideIcons.building, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _buildings
          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
          .toList(),
      onChanged: (value) => setState(() => _selectedLocation = value!),
      validator: (v) => v == null ? 'Pilih lokasi' : null,
    );
  }
}
