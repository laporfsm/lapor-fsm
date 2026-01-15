import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class AdminStaffPage extends StatefulWidget {
  const AdminStaffPage({super.key});

  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  // Mock data
  final List<Map<String, dynamic>> _staffList = [
    {
      'id': 1,
      'name': 'Budi Santoso',
      'email': 'budi@undip.ac.id',
      'role': 'teknisi',
      'isActive': true,
      'phone': '081234567890',
    },
    {
      'id': 2,
      'name': 'Andi Prasetyo',
      'email': 'andi@undip.ac.id',
      'role': 'teknisi',
      'isActive': true,
      'phone': '081234567891',
    },
    {
      'id': 3,
      'name': 'Citra Dewi',
      'email': 'citra@undip.ac.id',
      'role': 'supervisor',
      'isActive': true,
      'phone': '081234567892',
    },
    {
      'id': 4,
      'name': 'Dewi Kusuma',
      'email': 'dewi@undip.ac.id',
      'role': 'admin',
      'isActive': true,
      'phone': '081234567893',
    },
    {
      'id': 5,
      'name': 'Eko Wahyu',
      'email': 'eko@undip.ac.id',
      'role': 'teknisi',
      'isActive': false,
      'phone': '081234567894',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manajemen Staff'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _staffList.length,
        itemBuilder: (context, index) {
          return _buildStaffCard(_staffList[index]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(LucideIcons.userPlus),
        label: const Text('Tambah Staff'),
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final roleColor = _getRoleColor(staff['role']);
    final bool isActive = staff['isActive'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? null : Border.all(color: Colors.grey.shade300),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: roleColor.withOpacity(0.1),
                    child: Text(
                      staff['name'].toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              staff['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Gap(8),
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Nonaktif',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
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
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRoleLabel(staff['role']),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              Row(
                children: [
                  Icon(
                    LucideIcons.phone,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const Gap(6),
                  Text(
                    staff['phone'] ?? '-',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddEditDialog(staff),
                    icon: const Icon(LucideIcons.pencil, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _toggleStatus(staff),
                    icon: Icon(
                      isActive ? LucideIcons.userX : LucideIcons.userCheck,
                      size: 16,
                    ),
                    label: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                    style: TextButton.styleFrom(
                      foregroundColor: isActive ? Colors.red : Colors.green,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'teknisi':
        return Colors.blue;
      case 'supervisor':
        return Colors.purple;
      case 'admin':
        return const Color(0xFF059669);
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'teknisi':
        return 'Teknisi';
      case 'supervisor':
        return 'Supervisor';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  void _showAddEditDialog(Map<String, dynamic>? staff) {
    final isEditing = staff != null;
    final nameController = TextEditingController(text: staff?['name'] ?? '');
    final emailController = TextEditingController(text: staff?['email'] ?? '');
    final phoneController = TextEditingController(text: staff?['phone'] ?? '');
    final passwordController = TextEditingController();
    String selectedRole = staff?['role'] ?? 'teknisi';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(isEditing ? 'Edit Staff' : 'Tambah Staff Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(LucideIcons.user),
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: emailController,
                  enabled: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(LucideIcons.mail),
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'No. Telepon',
                    prefixIcon: Icon(LucideIcons.phone),
                  ),
                ),
                if (!isEditing) ...[
                  const Gap(12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(LucideIcons.lock),
                    ),
                  ),
                ],
                const Gap(16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(LucideIcons.userCog),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'teknisi', child: Text('Teknisi')),
                    DropdownMenuItem(
                      value: 'supervisor',
                      child: Text('Supervisor'),
                    ),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedRole = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Call API
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Staff berhasil diupdate'
                          : 'Staff berhasil ditambahkan',
                    ),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleStatus(Map<String, dynamic> staff) {
    final bool isActive = staff['isActive'] ?? false;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isActive ? 'Nonaktifkan Staff?' : 'Aktifkan Staff?'),
        content: Text(
          isActive
              ? 'Staff ${staff['name']} tidak akan bisa login setelah dinonaktifkan.'
              : 'Staff ${staff['name']} akan bisa login kembali setelah diaktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                staff['isActive'] = !isActive;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isActive ? 'Staff dinonaktifkan' : 'Staff diaktifkan',
                  ),
                  backgroundColor: isActive ? Colors.orange : Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );
  }
}
