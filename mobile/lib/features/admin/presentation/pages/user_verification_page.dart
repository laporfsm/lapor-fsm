import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:mobile/theme.dart';

class UserVerificationPage extends StatefulWidget {
  final String? searchQuery;
  const UserVerificationPage({super.key, this.searchQuery});

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
    if (widget.searchQuery != oldWidget.searchQuery) {
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
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      setState(() => _filteredPendingUsers = _allPendingUsers);
      return;
    }

    final query = widget.searchQuery!.toLowerCase();
    setState(() {
      _filteredPendingUsers = _allPendingUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final dept = (user['department'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            dept.contains(query);
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
                  LucideIcons.checkCircle,
                  size: 64,
                  color: Colors.green.withOpacity(0.5),
                ),
                const Gap(16),
                Text(
                  widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                      ? 'Tidak ditemukan user sesuai pencarian'
                      : 'Tidak ada user pending',
                  style: const TextStyle(color: Colors.grey),
                ),
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
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
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
