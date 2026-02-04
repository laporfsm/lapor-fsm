import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:mobile/core/theme.dart';

class UserVerificationPage extends StatefulWidget {
  final String? searchQuery;
  final Map<String, dynamic>? filters;

  const UserVerificationPage({super.key, this.searchQuery, this.filters});

  @override
  State<UserVerificationPage> createState() => _UserVerificationPageState();
}

class _UserVerificationPageState extends State<UserVerificationPage> {
  List<Map<String, dynamic>> _allPendingUsers = [];
  List<Map<String, dynamic>> _filteredPendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(UserVerificationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.filters != oldWidget.filters) {
      _filterData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await adminService.getPendingUsers();
    if (mounted) {
      setState(() {
        _allPendingUsers = users;
        _isLoading = false;
      });
      _filterData();
    }
  }

  void _filterData() {
    final query = (widget.searchQuery ?? '').toLowerCase();
    
    // Filters
    final filterDept = widget.filters?['department']?.toString().toLowerCase() ?? 'semua';
    
    setState(() {
      _filteredPendingUsers = _allPendingUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final dept = (user['department'] ?? '').toString().toLowerCase();
        
        // Search & Filter
        final matchesSearch = name.contains(query) ||
            email.contains(query) ||
            dept.contains(query);
            
        final matchesDept = filterDept == 'semua' || dept == filterDept;

        return matchesSearch && matchesDept;
      }).toList();
    });
  }

  Future<void> _verifyUser(String userId, String name) async {
    final success = await adminService.verifyUser(userId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $name berhasil diverifikasi')),
        );
        _loadData(); // Refresh list
        adminService.fetchPendingUserCount(); // Update badge
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memverifikasi user')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _filteredPendingUsers.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.searchX,
                  size: 64,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                const Gap(16),
                Text(
                  'Tidak ditemukan user pending',
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
                if (_allPendingUsers.isEmpty && (widget.searchQuery == null || widget.searchQuery!.isEmpty))
                   // Specialized hint if absolutely no pending users regardless of filter (optional, but keep it simple first)
                   const SizedBox.shrink(),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredPendingUsers.length,
            separatorBuilder: (context, index) => const Gap(12),
            itemBuilder: (context, index) {
              final user = _filteredPendingUsers[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            LucideIcons.user,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                user['email'] ?? '-',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Details
                    _DetailRow(
                      icon: LucideIcons.hash,
                      label: 'NIM/NIP',
                      value: user['nimNip'],
                    ),
                    const Gap(8),
                    _DetailRow(
                      icon: LucideIcons.building,
                      label: 'Departemen',
                      value: user['department'],
                    ),
                    const Gap(8),
                    _DetailRow(
                      icon: LucideIcons.phone,
                      label: 'No HP',
                      value: user['phone'],
                    ),

                    const Gap(16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _verifyUser(user['id'], user['name']),
                        icon: const Icon(LucideIcons.check, size: 18),
                        label: const Text('Verifikasi Akun'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const Gap(8),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const Gap(4),
        Expanded(
          child: Text(
            value ?? '-',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
