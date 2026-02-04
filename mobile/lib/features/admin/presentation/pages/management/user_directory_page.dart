import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/admin/services/export_service.dart';

class UserDirectoryPage extends StatefulWidget {
  final String? searchQuery;
  final Map<String, dynamic>? filters;

  const UserDirectoryPage({super.key, this.searchQuery, this.filters});

  @override
  State<UserDirectoryPage> createState() => _UserDirectoryPageState();
}

class _UserDirectoryPageState extends State<UserDirectoryPage> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(UserDirectoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.filters != oldWidget.filters) {
      _filterData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await adminService.getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
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
      _filteredUsers = _allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final role = (user['role'] ?? 'pelapor').toString().toLowerCase(); // Default to pelapor if missing
        final isActive = user['isActive'] == true;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_filteredUsers.isEmpty) {
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
              'Tidak ditemukan user',
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

    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          final isActive = user['isActive'] == true;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              onTap: () async {
                await context.push('/admin/users/${user['id']}');
                _loadData(); // Refresh on return
              },
              leading: CircleAvatar(
                backgroundColor: isActive
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                child: Icon(
                  LucideIcons.user,
                  color: isActive ? AppTheme.primaryColor : Colors.red,
                  size: 20,
                ),
              ),
              title: Text(
                user['name'] ?? 'No Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black : Colors.grey,
                  decoration: isActive ? null : TextDecoration.lineThrough,
                ),
              ),
              subtitle: Text(user['email'] ?? '-'),
              trailing: const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
  }
}
