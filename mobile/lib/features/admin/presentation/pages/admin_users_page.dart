import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data
  final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'name': 'Ahmad Fauzi',
      'email': 'ahmad.fauzi@students.undip.ac.id',
      'faculty': 'FSM',
      'department': 'Informatika',
      'reportsCount': 5,
    },
    {
      'id': 2,
      'name': 'Budi Hartono',
      'email': 'budi.hartono@students.undip.ac.id',
      'faculty': 'FSM',
      'department': 'Matematika',
      'reportsCount': 3,
    },
    {
      'id': 3,
      'name': 'Citra Lestari',
      'email': 'citra.lestari@lecturer.undip.ac.id',
      'faculty': 'FSM',
      'department': 'Fisika',
      'reportsCount': 8,
    },
    {
      'id': 4,
      'name': 'Dewi Anggraini',
      'email': 'dewi.anggraini@students.undip.ac.id',
      'faculty': 'FSM',
      'department': 'Kimia',
      'reportsCount': 2,
    },
    {
      'id': 5,
      'name': 'Eko Prasetyo',
      'email': 'eko.prasetyo@lecturer.undip.ac.id',
      'faculty': 'FSM',
      'department': 'Statistika',
      'reportsCount': 12,
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((u) {
      return u['name'].toString().toLowerCase().contains(query) ||
          u['email'].toString().toLowerCase().contains(query) ||
          u['department'].toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pengguna Terdaftar'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        actions: [
          IconButton(
            onPressed: _exportUsers,
            icon: const Icon(LucideIcons.download),
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari pengguna...',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildStat('Total', _users.length.toString(), Colors.blue),
                _buildStat(
                  'Mahasiswa',
                  _users
                      .where((u) => u['email'].toString().contains('students'))
                      .length
                      .toString(),
                  Colors.green,
                ),
                _buildStat(
                  'Dosen/Staff',
                  _users
                      .where((u) => u['email'].toString().contains('lecturer'))
                      .length
                      .toString(),
                  Colors.orange,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // User List
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.userX,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const Gap(16),
                        Text(
                          'Tidak ada pengguna ditemukan',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(_filteredUsers[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final bool isStudent = user['email'].toString().contains('students');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isStudent
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              child: Icon(
                isStudent ? LucideIcons.graduationCap : LucideIcons.briefcase,
                color: isStudent ? Colors.blue : Colors.orange,
                size: 20,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Gap(2),
                  Text(
                    user['email'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user['department'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const Gap(8),
                      Icon(
                        LucideIcons.fileText,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const Gap(4),
                      Text(
                        '${user['reportsCount']} laporan',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showUserDetail(user),
              icon: const Icon(LucideIcons.eye, size: 18),
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(20),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF059669).withOpacity(0.1),
                  child: Text(
                    user['name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user['email'].toString().contains('students')
                            ? 'Mahasiswa'
                            : 'Dosen/Staff',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(20),
            _buildDetailItem(LucideIcons.mail, 'Email', user['email']),
            _buildDetailItem(LucideIcons.building, 'Fakultas', user['faculty']),
            _buildDetailItem(
              LucideIcons.graduationCap,
              'Jurusan',
              user['department'],
            ),
            _buildDetailItem(
              LucideIcons.fileText,
              'Total Laporan',
              '${user['reportsCount']} laporan',
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  void _exportUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting data pengguna...'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }
}
