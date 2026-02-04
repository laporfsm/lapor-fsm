import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:mobile/core/theme.dart';


class StaffManagementPage extends StatefulWidget {
  final String? searchQuery;
  final bool shouldOpenAddDialog;
  final Map<String, dynamic>? filters; // Add filters param

  const StaffManagementPage({
    super.key,
    this.searchQuery,
    this.shouldOpenAddDialog = false,
    this.filters,
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
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.filters != oldWidget.filters) {
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
    final query = (widget.searchQuery ?? '').toLowerCase();
    
    // Filters
    final filterRole = widget.filters?['role']?.toString().toLowerCase() ?? 'semua';
    final filterStatus = widget.filters?['status']?.toString().toLowerCase() ?? 'semua';

    setState(() {
      _filteredStaff = _allStaff.where((staff) {
        final name = (staff['name'] ?? '').toString().toLowerCase();
        final email = (staff['email'] ?? '').toString().toLowerCase();
        final role = (staff['role'] ?? '').toString().toLowerCase();
        final isActive = staff['isActive'] == true;

        // Search Match
        final matchesSearch = name.contains(query) || email.contains(query);

        // Filter Match
        final matchesRole = filterRole == 'semua' || role == filterRole;
        final matchesStatus = filterStatus == 'semua' ||
            (filterStatus == 'aktif' && isActive) ||
            (filterStatus == 'nonaktif' && !isActive);

        return matchesSearch && matchesRole && matchesStatus;
      }).toList();
    });
  }

  void _showAddStaffDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddStaffBottomSheet(),
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
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              final success = await adminService.updateStaff(
                staff['id'].toString(),
                {'password': passwordController.text},
              );

              navigator.pop();
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Password berhasil direset')),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Gagal reset password')),
                );
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
      if (!mounted) return;
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Staff dinonaktifkan' : 'Staff diaktifkan'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_filteredStaff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ditemukan staff',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Coba sesuaikan filter atau pencarian Anda',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStaff.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final staff = _filteredStaff[index];
        return _buildStaffCard(staff);
      },
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final role = staff['role']?.toString() ?? '';
    final isActive = staff['isActive'] == true;

    Color roleColor;
    Color roleBgColor;
    
    switch (role) {
      case 'admin':
        roleColor = Colors.purple;
        roleBgColor = Colors.purple.withValues(alpha: 0.1);
        break;
      case 'pj_gedung':
        roleColor = Colors.orange;
        roleBgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'teknisi':
        roleColor = Colors.blue;
        roleBgColor = Colors.blue.withValues(alpha: 0.1);
        break;
      default: // supervisor
        roleColor = AppTheme.primaryColor;
        roleBgColor = AppTheme.primaryColor.withValues(alpha: 0.1);
    }

    return Opacity(
      opacity: isActive ? 1.0 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isActive ? Colors.grey.shade100 : Colors.red.shade100,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              staff['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isActive ? Colors.black : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          if (!isActive) ...[
                            const Gap(8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Text(
                                'NONAKTIF',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Gap(4),
                      Text(
                        staff['email'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? roleBgColor : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: isActive ? roleColor : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: LucideIcons.key,
                      color: Colors.orange,
                      tooltip: 'Reset Password',
                      onTap: () => _showResetPasswordDialog(staff),
                    ),
                    const Gap(8),
                    _buildActionButton(
                      icon: LucideIcons.pencil,
                      color: Colors.blue,
                      tooltip: 'Edit',
                      onTap: () => _showEditStaffDialog(staff),
                    ),
                    const Gap(8),
                    _buildActionButton(
                      icon: isActive ? LucideIcons.userX : LucideIcons.userCheck,
                      color: isActive ? Colors.red : Colors.green,
                      tooltip: isActive ? 'Nonaktifkan' : 'Aktifkan',
                      onTap: () => _toggleStaffStatus(staff),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }


}

class AddStaffBottomSheet extends StatefulWidget {
  const AddStaffBottomSheet({super.key});

  @override
  State<AddStaffBottomSheet> createState() => _AddStaffBottomSheetState();
}

class _AddStaffBottomSheetState extends State<AddStaffBottomSheet> {
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
          const SnackBar(
            content: Text('Staff berhasil ditambahkan'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambahkan staff'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.adminColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.userPlus,
                    color: AppTheme.adminColor,
                  ),
                ),
                const Gap(16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Staff Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Lengkapi data untuk membuat akun staff',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildField(
                    controller: _nameController,
                    label: 'Nama Lengkap',
                    icon: LucideIcons.user,
                    validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const Gap(16),
                  _buildField(
                    controller: _emailController,
                    label: 'Email',
                    icon: LucideIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? 'Email wajib diisi' : null,
                  ),
                  const Gap(16),
                  _buildField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: LucideIcons.key,
                    obscureText: true,
                    validator: (v) => v!.length < 6 ? 'Min 6 karakter' : null,
                  ),
                  const Gap(16),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: InputDecoration(
                      labelText: 'Role Akses',
                      prefixIcon: const Icon(LucideIcons.shieldCheck, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
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
          const Gap(32),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.adminColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Buat Akun Staff',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          const Gap(12),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.adminColor),
        ),
      ),
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
                initialValue: _role,
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
