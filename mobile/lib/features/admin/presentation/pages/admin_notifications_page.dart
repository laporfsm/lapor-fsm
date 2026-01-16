import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Admin Notifications Page - untuk notifikasi pendaftaran baru
class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  // Mock data - notifikasi pendaftaran baru
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'name': 'Rudi Setiawan',
      'email': 'rudi.setiawan@gmail.com',
      'time': DateTime.now().subtract(const Duration(minutes: 30)),
      'isRead': false,
    },
    {
      'id': 2,
      'name': 'Sri Wahyuni',
      'email': 'sri.wahyuni@yahoo.com',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
    },
    {
      'id': 3,
      'name': 'Agus Pratama',
      'email': 'agus.pratama@gmail.com',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': true,
    },
  ];

  int get _unreadCount => _notifications.where((n) => !n['isRead']).length;

  void _markAsRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua ditandai sudah dibaca'),
        backgroundColor: Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteNotification(int id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifikasi dihapus'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Notifikasi?'),
        content: const Text('Notifikasi ini akan dihapus permanen.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteNotification(id);
    }
  }

  void _deleteAllNotifications() {
    if (_notifications.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua?'),
        content: const Text('Apakah Anda yakin ingin menghapus semua notifikasi?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                _notifications.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua notifikasi dihapus'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            if (_unreadCount > 0)
              IconButton(
                onPressed: _markAllAsRead,
                icon: const Icon(LucideIcons.checkCheck, color: Colors.white),
                tooltip: 'Baca Semua',
              ),
            IconButton(
              onPressed: _deleteAllNotifications,
              icon: const Icon(LucideIcons.trash2, color: Colors.white),
              tooltip: 'Hapus Semua',
            ),
            const Gap(8),
          ],
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) =>
                  _buildNotificationCard(_notifications[index]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bellOff, size: 48, color: Colors.grey.shade300),
          const Gap(16),
          Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const Gap(4),
          Text(
            'Notifikasi pendaftaran baru akan muncul di sini',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['isRead'] ?? true;

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Notifikasi?'),
            content: const Text('Notifikasi ini akan dihapus permanen.'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: GestureDetector(
        onTap: () {
          _markAsRead(notification['id']);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: isRead
                ? null
                : Border.all(
                    color: const Color(0xFF3B82F6).withAlpha(100), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isRead ? 8 : 15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.userPlus,
                      color: Color(0xFF3B82F6), size: 20),
                ),
                const Gap(12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pendaftaran Baru',
                              style: TextStyle(
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          // Explicit delete button on card
                          IconButton(
                            icon: Icon(LucideIcons.x, size: 16, color: Colors.grey.shade400),
                            onPressed: () => _confirmDelete(notification['id']),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        '${notification['name']} mendaftar dan menunggu verifikasi',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        _formatTime(notification['time']),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }
}
