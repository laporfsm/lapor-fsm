import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDepartment = 'all';

  // Mock data
  final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'name': 'Ahmad Fauzi',
      'email': 'ahmad.fauzi@students.undip.ac.id',
      'department': 'Informatika',
      'reportsCount': 5,
    },
    {
      'id': 2,
      'name': 'Budi Hartono',
      'email': 'budi.hartono@students.undip.ac.id',
      'department': 'Matematika',
      'reportsCount': 3,
    },
    {
      'id': 3,
      'name': 'Citra Lestari',
      'email': 'citra.lestari@lecturer.undip.ac.id',
      'department': 'Fisika',
      'reportsCount': 8,
    },
    {
      'id': 4,
      'name': 'Dewi Anggraini',
      'email': 'dewi.anggraini@students.undip.ac.id',
      'department': 'Kimia',
      'reportsCount': 2,
    },
    {
      'id': 5,
      'name': 'Eko Prasetyo',
      'email': 'eko.prasetyo@lecturer.undip.ac.id',
      'department': 'Statistika',
      'reportsCount': 12,
    },
    {
      'id': 6,
      'name': 'Fitri Handayani',
      'email': 'fitri@gmail.com',
      'department': 'Pengunjung',
      'reportsCount': 1,
    },
  ];

  List<String> get _departments {
    final deps = _users.map((u) => u['department'] as String).toSet().toList();
    deps.sort();
    return ['all', ...deps];
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var list = _users;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      list = list.where((u) {
        return u['name'].toString().toLowerCase().contains(query) ||
            u['email'].toString().toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedDepartment != 'all') {
      list = list.where((u) => u['department'] == _selectedDepartment).toList();
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
          'Data Pengguna',
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
                  hintText: 'Cari pengguna...',
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

          // Department Filter
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _departments.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (context, index) {
                final dept = _departments[index];
                final isSelected = _selectedDepartment == dept;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDepartment = dept),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF059669)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF059669)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dept == 'all' ? 'Semua' : dept,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // List
          Expanded(
            child: _filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) =>
                        _buildUserCard(_filteredUsers[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.userX, size: 48, color: Colors.grey.shade300),
          const Gap(16),
          Text(
            'Tidak ada pengguna',
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

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isExternal = !(user['email'] as String).contains('undip.ac.id');

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserDetail(user),
          borderRadius: BorderRadius.circular(12),
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
                              user['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isExternal) ...[
                            const Gap(8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Eksternal',
                                style: TextStyle(
                                    fontSize: 9, color: Color(0xFFF59E0B)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Gap(4),
                      Text(
                        user['email'],
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withAlpha(26),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user['department'],
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Gap(8),
                          Icon(LucideIcons.fileText,
                              size: 12, color: Colors.grey.shade400),
                          const Gap(4),
                          Text(
                            '${user['reportsCount']} laporan',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  LucideIcons.chevronRight,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    final isExternal = !(user['email'] as String).contains('undip.ac.id');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isExternal) ...[
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withAlpha(26),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Eksternal',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Gap(4),
                        Text(
                          user['email'],
                          style:
                              TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Info
              _InfoRow(
                icon: LucideIcons.building,
                label: 'Jurusan',
                value: user['department'],
              ),
              const Gap(12),
              _InfoRow(
                icon: LucideIcons.fileText,
                label: 'Total Laporan',
                value: '${user['reportsCount']} laporan',
              ),
              const Gap(20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}
