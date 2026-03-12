import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/api_service.dart';

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
    final filterDept = widget.filters?['department']?.toString().toLowerCase() ?? 'semua';
    
    setState(() {
      _filteredPendingUsers = _allPendingUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final dept = (user['department'] ?? '').toString().toLowerCase();
        
        final matchesSearch = name.contains(query) ||
            email.contains(query) ||
            dept.contains(query);
            
        final matchesDept = filterDept == 'semua' || dept == filterDept;

        return matchesSearch && matchesDept;
      }).toList();
    });
  }

  Future<void> _verifyUser(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: Colors.green),
            const Gap(12),
            const Text('Konfirmasi Verifikasi'),
          ],
        ),
        content: Text(
          'Pastikan Anda telah memeriksa identitas $name. Berikan akses sistem sekarang?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Nanti Dulu', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Verifikasi Sekarang'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await adminService.verifyUser(userId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                const Gap(12),
                Text('User $name berhasil diaktifkan'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadData();
        adminService.fetchPendingUserCount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memverifikasi user')),
        );
      }
    }
  }

  void _viewIdCard(String? url) {
    if (url == null || url.isEmpty) return;
    final fullUrl = url.startsWith('http') ? url : '${ApiService.baseUrl}/$url';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(LucideIcons.xCircle, color: Colors.white, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(fullUrl, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _filteredPendingUsers.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _filteredPendingUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredPendingUsers[index];
              return _VerificationCard(
                user: user,
                onVerify: () => _verifyUser(user['id'], user['name']),
                onViewId: () => _viewIdCard(user['idCardUrl']),
              );
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.userPlus,
              size: 64,
              color: Colors.grey.shade300,
            ),
          ),
          const Gap(20),
          Text(
            'Semua Sudah Bersih!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const Gap(8),
          Text(
            'Tidak ada antrian pendaftaran saat ini.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onVerify;
  final VoidCallback onViewId;

  const _VerificationCard({
    required this.user,
    required this.onVerify,
    required this.onViewId,
  });

  @override
  Widget build(BuildContext context) {
    final idCardUrl = user['idCardUrl'];
    final fullUrl = idCardUrl != null 
        ? (idCardUrl.startsWith('http') ? idCardUrl : '${ApiService.baseUrl}/$idCardUrl')
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header: User Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
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
                  _buildTypeTag(user['email']),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID Card Preview Thumbnail
                  if (fullUrl != null)
                    GestureDetector(
                      onTap: onViewId,
                      child: Container(
                        width: 100,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                          image: DecorationImage(
                            image: NetworkImage(fullUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.maximize2,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 100,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.imageOff, color: Colors.grey.shade300),
                    ),
                  
                  const Gap(16),
                  
                  // Vital Details
                  Expanded(
                    child: Column(
                      children: [
                        _infoSmall(LucideIcons.hash, user['nimNip'] ?? '-'),
                        const Gap(6),
                        _infoSmall(LucideIcons.building, user['department'] ?? '-'),
                        const Gap(6),
                        _infoSmall(LucideIcons.phone, user['phone'] ?? '-'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Gap(16),

            // Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  const Icon(LucideIcons.clock, size: 12, color: Colors.grey),
                  const Gap(4),
                  Text(
                    'Menunggu Verifikasi',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Terima Registrasi', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTag(String? email) {
    final isUndip = email?.toLowerCase().endsWith('undip.ac.id') ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUndip ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isUndip ? 'UNDIP' : 'EXTERNAL',
        style: TextStyle(
          color: isUndip ? Colors.blue.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _infoSmall(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade400),
        const Gap(8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
