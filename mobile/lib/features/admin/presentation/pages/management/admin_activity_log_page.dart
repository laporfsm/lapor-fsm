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
  String _dateFilter = 'Semua';
  int _activeTabIndex = 0;
  String _adminCategoryFilter = 'Semua';
  String _verificationCategoryFilter = 'Semua';
  String _reportCategoryFilter = 'Semua';
  List<Map<String, dynamic>> _allLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (mounted) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
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
      final logTime = _getLogTime(log);
      final matchesDate = _matchesDateFilter(logTime);
      final matchesSearch =
          log['user'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log['details'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log['action'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesType = log['type'] == type;
      final matchesCategory = _matchesCategoryFilter(log, type);

      return matchesSearch && matchesType && matchesDate && matchesCategory;
    }).toList();
  }

  DateTime? _getLogTime(Map<String, dynamic> log) {
    final time = log['time'];
    if (time is DateTime) {
      return time;
    }
    if (time is String) {
      return DateTime.tryParse(time);
    }
    return null;
  }

  bool _matchesDateFilter(DateTime? time) {
    if (_dateFilter == 'Semua' || time == null) {
      return true;
    }

    final now = DateTime.now();
    if (_dateFilter == 'Hari ini') {
      return time.year == now.year &&
          time.month == now.month &&
          time.day == now.day;
    }

    final cutoffDays = _dateFilter == '7 hari' ? 7 : 30;
    final cutoff = now.subtract(Duration(days: cutoffDays));
    return !time.isBefore(cutoff);
  }

  bool _matchesCategoryFilter(Map<String, dynamic> log, String type) {
    final selected = _getSelectedCategory(type);
    if (selected == 'Semua') return true;
    final category = _getCategoryValue(log, type);
    return category == selected;
  }

  String _getSelectedCategory(String type) {
    switch (type) {
      case 'Admin':
        return _adminCategoryFilter;
      case 'Verifikasi':
        return _verificationCategoryFilter;
      case 'Laporan':
        return _reportCategoryFilter;
      default:
        return 'Semua';
    }
  }

  String _getCategoryValue(Map<String, dynamic> log, String type) {
    if (type == 'Laporan') {
      final from = log['fromStatus']?.toString();
      final to = log['toStatus']?.toString();
      if (from != null && to != null && from.isNotEmpty && to.isNotEmpty) {
        return '$from → $to';
      }

      final details = log['details']?.toString() ?? '';
      final match = RegExp(
        r'Status changed from ([^ ]+) to ([^ ]+)',
        caseSensitive: false,
      ).firstMatch(details);
      if (match != null) {
        return '${match.group(1)} → ${match.group(2)}';
      }
    }

    return log['action']?.toString() ?? 'Lainnya';
  }

  List<String> _getCategoriesForType(String type) {
    final categories = _allLogs
        .where((log) => log['type'] == type)
        .map((log) => _getCategoryValue(log, type))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Semua', ...categories];
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
            Tab(text: 'Riwayat Admin'),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(LucideIcons.filter, size: 18),
                const Gap(8),
                const Text(
                  'Filter:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Gap(12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua'),
                        _buildFilterChip('Hari ini'),
                        _buildFilterChip('7 hari'),
                        _buildFilterChip('30 hari'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildCategoryFilterRow(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLogList('Admin'),
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

  Widget _buildFilterChip(String label) {
    final selected = _dateFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (value) {
          if (!value) return;
          setState(() => _dateFilter = label);
        },
        selectedColor: AppTheme.adminColor.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? AppTheme.adminColor : Colors.grey.shade700,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCategoryFilterRow() {
    final type = _activeTabIndex == 0
        ? 'Admin'
        : _activeTabIndex == 1
            ? 'Verifikasi'
            : 'Laporan';
    if (type == 'Verifikasi') {
      return const SizedBox.shrink();
    }
    final categories = _getCategoriesForType(type);
    if (categories.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(LucideIcons.tags, size: 18),
          const Gap(8),
          Text(
            type == 'Admin'
                ? 'Status:'
                : 'Perubahan:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Gap(12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories
                    .map((category) => _buildCategoryChip(category, type))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String type) {
    final selected = _getSelectedCategory(type) == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (value) {
          if (!value) return;
          setState(() {
            if (type == 'Admin') {
              _adminCategoryFilter = label;
            } else if (type == 'Verifikasi') {
              _verificationCategoryFilter = label;
            } else {
              _reportCategoryFilter = label;
            }
          });
        },
        selectedColor: AppTheme.adminColor.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? AppTheme.adminColor : Colors.grey.shade700,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
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
      case 'Admin':
        icon = LucideIcons.userCog;
        color = Colors.indigo;
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
