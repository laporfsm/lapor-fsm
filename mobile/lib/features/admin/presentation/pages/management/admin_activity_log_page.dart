import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/admin/services/export_service.dart';
import 'package:mobile/features/admin/services/admin_service.dart';
import 'package:intl/intl.dart';

class AdminActivityLogPage extends StatefulWidget {
  const AdminActivityLogPage({super.key});

  @override
  State<AdminActivityLogPage> createState() => _AdminActivityLogPageState();
}

class _AdminActivityLogPageState extends State<AdminActivityLogPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  List<Map<String, dynamic>> _allLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final logs = await adminService.getLogs();
    if (mounted) {
      setState(() {
        _allLogs = logs;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredLogs(String type) {
    return _allLogs.where((log) {
      final matchesSearch =
          log['user'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log['details'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log['action'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesType = log['type'] == type;

      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Log Sistem',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.adminColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ExportService.exportData(
              context,
              'Log Aktivitas Sistem',
              'logs',
              primaryColor: AppTheme.adminColor,
            ),
            icon: const Icon(LucideIcons.download, color: Colors.white),
            tooltip: 'Export Log',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'Aktivitas User'),
            Tab(text: 'Verifikasi User'),
            Tab(text: 'Logs Laporan'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari log aktivitas...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLogList('User'),
                      _buildLogList('Verifikasi'),
                      _buildLogList('Laporan'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(String type) {
    final filtered = _getFilteredLogs(type);
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada log ${type.toLowerCase()} ditemukan',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (c, i) => const Gap(12),
      itemBuilder: (context, index) {
        final log = filtered[index];
        return _buildLogItem(log);
      },
    );
  }


  Widget _buildLogItem(Map<String, dynamic> log) {
    IconData icon;
    Color color;

    switch (log['type']) {
      case 'Login':
        icon = LucideIcons.logIn;
        color = Colors.green;
        break;
      case 'Laporan':
        icon = LucideIcons.fileText;
        color = Colors.blue;
        break;
      case 'User':
        icon = LucideIcons.user;
        color = Colors.orange;
        break;
      case 'Verifikasi':
        icon = LucideIcons.userCheck;
        color = Colors.purple;
        break;
      default:
        icon = LucideIcons.activity;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log['action'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(log['time']),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(log['details'], style: const TextStyle(fontSize: 13)),
                const Gap(4),
                Text(
                  'Oleh: ${log['user']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
