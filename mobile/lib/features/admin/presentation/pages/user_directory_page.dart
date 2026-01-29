import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/admin/services/export_service.dart';

class UserDirectoryPage extends StatefulWidget {
  final String? searchQuery;
  const UserDirectoryPage({super.key, this.searchQuery});

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
    if (widget.searchQuery != oldWidget.searchQuery) {
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
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      setState(() => _filteredUsers = _allUsers);
      return;
    }

    final query = widget.searchQuery!.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to blend with tab
      floatingActionButton: FloatingActionButton(
        onPressed: () => ExportService.exportData(context, 'Data User', 'user'),
        backgroundColor: AppTheme.adminColor,
        tooltip: 'Export User',
        child: const Icon(LucideIcons.download, color: Colors.white),
      ),
      body: ListView.builder(
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
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
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
      ),
    );
  }
}
