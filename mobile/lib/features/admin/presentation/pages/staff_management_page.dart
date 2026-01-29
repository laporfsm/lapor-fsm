import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/admin/services/export_service.dart';

class StaffManagementPage extends StatefulWidget {
  final String? searchQuery;
  final bool shouldOpenAddDialog; // New parameter

  const StaffManagementPage({
    super.key,
    this.searchQuery,
    this.shouldOpenAddDialog = false,
  });

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  List<Map<String, dynamic>> _allStaff = [];
  List<Map<String, dynamic>> _filteredStaff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.shouldOpenAddDialog) {
      // Delay to ensure context is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddStaffDialog();
      });
    }
  }

  @override
  void didUpdateWidget(StaffManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _filterData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final staff = await adminService.getStaff();
    if (mounted) {
      setState(() {
        _allStaff = staff;
        _isLoading = false;
      });
      _filterData();
    }
  }

  void _filterData() {
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      setState(() => _filteredStaff = _allStaff);
      return;
    }

    final query = widget.searchQuery!.toLowerCase();
    setState(() {
      _filteredStaff = _allStaff.where((staff) {
        final name = (staff['name'] ?? '').toString().toLowerCase();
        final email = (staff['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddStaffDialog(),
    ).then((value) {
      if (value == true) _loadData(); // Refresh if added
    });
  }

  void _showEditStaffDialog(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => _EditStaffDialog(staff: staff),
    ).then((value) {
      if (value == true) _loadData();
    });
  }

  void _showResetPasswordDialog(Map<String, dynamic> staff) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password - ${staff['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan password baru untuk staff ini.'),
            const Gap(16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password Baru'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password min 6 karakter')),
                );
                return;
              }
              final success = await adminService.updateStaff(
                staff['id'].toString(),
                {'password': passwordController.text},
              );
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password berhasil direset')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal reset password')),
                  );
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStaffStatus(Map<String, dynamic> staff) async {
    final isActive = staff['isActive'] == true;
    final success = await adminService.updateStaff(staff['id'].toString(), {
      'isActive': !isActive,
    });
    if (success) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive ? 'Staff dinonaktifkan' : 'Staff diaktifkan',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'export_staff',
            onPressed: () =>
                ExportService.exportData(context, 'Data Staff', 'staff'),
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.adminColor,
            tooltip: 'Export Staff',
            child: const Icon(LucideIcons.download),
          ),
          const Gap(12),
          FloatingActionButton.extended(
            heroTag: 'add_staff',
            onPressed: _showAddStaffDialog,
            backgroundColor: AppTheme.adminColor,
            foregroundColor: Colors.white,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Tambah Staff'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredStaff.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final staff = _filteredStaff[index];
                final role = staff['role'];
                final isActive = staff['isActive'] == true;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isActive
                            ? (role == 'admin'
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.indigo.withOpacity(0.1))
                            : Colors.grey.withOpacity(0.1),
                        child: Icon(
                          role == 'admin'
                              ? LucideIcons.shield
                              : LucideIcons.userCog,
                          color: isActive
                              ? (role == 'admin'
                                    ? Colors.purple
                                    : Colors.indigo)
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              role.toString().toUpperCase(),
                              style: TextStyle(
                                color: role == 'admin'
                                    ? Colors.purple
                                    : Colors.indigo,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              staff['email'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NON-AKTIF',
                            style: TextStyle(color: Colors.red, fontSize: 10),
                          ),
                        ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditStaffDialog(staff);
                          } else if (value == 'reset_password') {
                            _showResetPasswordDialog(staff);
                          } else if (value == 'toggle_status') {
                            _toggleStaffStatus(staff);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(LucideIcons.edit, size: 18),
                                Gap(8),
                                Text('Edit Data'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reset_password',
                            child: Row(
                              children: [
                                Icon(LucideIcons.key, size: 18),
                                Gap(8),
                                Text('Reset Password'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: Row(
                              children: [
                                Icon(
                                  isActive
                                      ? LucideIcons.ban
                                      : LucideIcons.checkCircle,
                                  size: 18,
                                  color: isActive ? Colors.red : Colors.green,
                                ),
                                const Gap(8),
                                Text(
                                  isActive ? 'Nonaktifkan' : 'Aktifkan',
                                  style: TextStyle(
                                    color: isActive ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: const Icon(
                          LucideIcons.moreVertical,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _AddStaffDialog extends StatefulWidget {
  const _AddStaffDialog();

  @override
  State<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<_AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'supervisor'; // Default role
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await adminService.addStaff({
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'role': _role,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff berhasil ditambahkan')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan staff')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Staff Baru'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const Gap(12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const Gap(12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Min 6 karakter' : null,
              ),
              const Gap(12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(
                    value: 'supervisor',
                    child: Text('Supervisor'),
                  ),
                  DropdownMenuItem(
                    value: 'pj_gedung',
                    child: Text('PJ Gedung'),
                  ),
                  DropdownMenuItem(value: 'teknisi', child: Text('Teknisi')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Batal'),
            ),
            const Gap(8),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.adminColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditStaffDialog extends StatefulWidget {
  final Map<String, dynamic> staff;

  const _EditStaffDialog({required this.staff});

  @override
  State<_EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends State<_EditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late String _role;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.staff['name'];
    _emailController.text = widget.staff['email'];
    _phoneController.text = widget.staff['phone'] ?? '';
    _role = widget.staff['role'];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await adminService
        .updateStaff(widget.staff['id'].toString(), {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'role': _role,
        });

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff berhasil diupdate')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal update staff')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Staff'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const Gap(12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const Gap(12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'No HP'),
              ),
              const Gap(12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(
                    value: 'supervisor',
                    child: Text('Supervisor'),
                  ),
                  DropdownMenuItem(
                    value: 'pj_gedung',
                    child: Text('PJ Gedung'),
                  ),
                  DropdownMenuItem(value: 'teknisi', child: Text('Teknisi')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
