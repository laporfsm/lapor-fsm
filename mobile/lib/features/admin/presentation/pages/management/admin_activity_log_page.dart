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

class _AdminActivityLogPageState extends State<AdminActivityLogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua'; // Semua, Login, Laporan, User

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final logs = await adminService.getLogs();
    if (mounted) {
      setState(() {
        _allLogs = logs;
        _isLoading = false;
        _filterLogs();
      });
    }
  }

  void _filterLogs() {
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        final matchesSearch =
            log['user'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            log['details'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            log['action'].toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesType =
            _selectedFilter == 'Semua' || log['type'] == _selectedFilter;

        return matchesSearch && matchesType;
      }).toList();
    });
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExportOptions(context),
        backgroundColor: AppTheme.adminColor,
        tooltip: 'Export Log',
        child: const Icon(LucideIcons.download, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Header (Filters removed as backend only returns User logs)
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
                _searchQuery = val;
                _filterLogs();
              },
            ),
          ),

          // Log List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                    ? const Center(child: Text('Tidak ada log ditemukan'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredLogs.length,
                        separatorBuilder: (c, i) => const Gap(12),
                        itemBuilder: (context, index) {
                          final log = _filteredLogs[index];
                          return _buildLogItem(log);
                        },
                      ),
          ),
        ],
      ),
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
                      DateFormat('HH:mm').format(log['time']),
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

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Log Sistem',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Gap(20),
              ListTile(
                leading: const Icon(LucideIcons.fileSpreadsheet, color: Colors.green),
                title: const Text('Export ke Excel (.xlsx)'),
                onTap: () {
                  Navigator.pop(context);
                  ExportService.exportData(context, 'Log Sistem User', 'log', data: _filteredLogs);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.fileText, color: Colors.red),
                title: const Text('Export ke PDF (.pdf)'),
                onTap: () {
                  Navigator.pop(context);
                  ExportService.exportAdminLogsPdf(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
