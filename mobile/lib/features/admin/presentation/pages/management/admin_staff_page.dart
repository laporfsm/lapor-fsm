import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class AdminStaffPage extends StatefulWidget {
  const AdminStaffPage({super.key});

  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

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

  List<Map<String, dynamic>> get _filteredStaff {
    var list = _staffList;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      list = list.where((s) {
        return s['name'].toString().toLowerCase().contains(query) ||
            s['email'].toString().toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedFilter != 'all') {
      list = list.where((s) => s['role'] == _selectedFilter).toList();
    }

    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        ),
        title: const Text(
          'Manajemen Staff',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: const Color(0xFF059669),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari staff...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(LucideIcons.search,
                      color: Colors.grey.shade400, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x,
                              color: Colors.grey.shade400, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Filter
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _buildFilterChip('all', 'Semua'),
                const Gap(8),
                _buildFilterChip('teknisi', 'Teknisi'),
                const Gap(8),
                _buildFilterChip('supervisor', 'Supervisor'),
                const Gap(8),
                _buildFilterChip('admin', 'Admin'),
              ],
            ),
          ),

          // List
          Expanded(
            child: _filteredStaff.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredStaff.length,
                    itemBuilder: (context, index) =>
                        _buildStaffCard(_filteredStaff[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSheet(null),
        backgroundColor: const Color(0xFF059669),
        child: const Icon(LucideIcons.userPlus, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 48, color: Colors.grey.shade300),
          const Gap(16),
          Text(
            'Tidak ada staff',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final roleColor = _getRoleColor(staff['role']);
    final bool isActive = staff['isActive'] ?? false;

    return Opacity(
      opacity: isActive ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            staff['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isActive) ...[
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Nonaktif',
                              style: TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(4),
                    Text(
                      staff['email'],
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getRoleLabel(staff['role']),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: LucideIcons.pencil,
                    color: const Color(0xFF3B82F6),
                    onTap: () => _showAddEditSheet(staff),
                  ),
                  const Gap(6),
                  _ActionButton(
                    icon: isActive ? LucideIcons.userX : LucideIcons.userCheck,
                    color: isActive
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF22C55E),
                    onTap: () => _toggleStatus(staff),
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
        return const Color(0xFF3B82F6);
      case 'supervisor':
        return const Color(0xFF8B5CF6);
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

  void _toggleStatus(Map<String, dynamic> staff) {
    final bool isActive = staff['isActive'] ?? false;
    setState(() {
      staff['isActive'] = !isActive;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isActive ? 'Staff dinonaktifkan' : 'Staff diaktifkan'),
        backgroundColor:
            isActive ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddEditSheet(Map<String, dynamic>? staff) {
    final isEditing = staff != null;
    final nameController = TextEditingController(text: staff?['name'] ?? '');
    final emailController = TextEditingController(text: staff?['email'] ?? '');
    final phoneController = TextEditingController(text: staff?['phone'] ?? '');
    String selectedRole = staff?['role'] ?? 'teknisi';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    isEditing ? 'Edit Staff' : 'Tambah Staff',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(20),

                  // Name
                  _FormField(
                    label: 'Nama',
                    controller: nameController,
                    hint: 'Nama lengkap',
                  ),
                  const Gap(12),

                  // Email
                  _FormField(
                    label: 'Email',
                    controller: emailController,
                    hint: 'email@undip.ac.id',
                    enabled: !isEditing,
                  ),
                  const Gap(12),

                  // Phone
                  _FormField(
                    label: 'No. Telepon',
                    controller: phoneController,
                    hint: '08xxxxxxxxxx',
                  ),
                  const Gap(12),

                  // Role
                  const Text(
                    'Role',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      _RoleChip(
                        label: 'Teknisi',
                        isSelected: selectedRole == 'teknisi',
                        color: const Color(0xFF3B82F6),
                        onTap: () =>
                            setSheetState(() => selectedRole = 'teknisi'),
                      ),
                      const Gap(8),
                      _RoleChip(
                        label: 'Supervisor',
                        isSelected: selectedRole == 'supervisor',
                        color: const Color(0xFF8B5CF6),
                        onTap: () =>
                            setSheetState(() => selectedRole = 'supervisor'),
                      ),
                      const Gap(8),
                      _RoleChip(
                        label: 'Admin',
                        isSelected: selectedRole == 'admin',
                        color: const Color(0xFF059669),
                        onTap: () =>
                            setSheetState(() => selectedRole = 'admin'),
                      ),
                    ],
                  ),
                  const Gap(24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing
                                    ? 'Staff diperbarui'
                                    : 'Staff ditambahkan'),
                                backgroundColor: const Color(0xFF22C55E),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(isEditing ? 'Simpan' : 'Tambah'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(26),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool enabled;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const Gap(6),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: enabled ? const Color(0xFFF8FAFC) : Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF059669)),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withAlpha(26),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : color.withAlpha(51),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
