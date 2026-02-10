import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/admin/presentation/pages/management/staff_management_page.dart';
import 'package:mobile/features/admin/presentation/pages/management/user_directory_page.dart';
import 'package:mobile/features/admin/presentation/pages/management/user_verification_page.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/admin/services/export_service.dart';

class AdminUsersPage extends StatefulWidget {
  final int initialIndex;
  final String? action; // New param

  const AdminUsersPage({super.key, this.initialIndex = 0, this.action});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _staffRefreshKey = 0; // Key to force refresh staff list

  // Store filters for each tab: 0=Directory, 1=Verification, 2=Staff
  final List<Map<String, dynamic>> _tabFilters = [
    {'role': 'Semua', 'status': 'Semua'}, // Directory
    {'department': 'Semua'}, // Verification
    {'role': 'Semua', 'status': 'Aktif'}, // Staff
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(AdminUsersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _tabController.animateTo(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Manajemen User',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.adminColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          // Add Staff button - only show on Staff tab (index 2)
          if (_tabController.index == 2)
            IconButton(
              icon: const Icon(LucideIcons.userPlus, color: Colors.white),
              tooltip: 'Tambah Staff',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddStaffBottomSheet(),
                ).then((value) {
                  if (value == true) {
                    setState(() {
                      _staffRefreshKey++; // Force reload
                    });
                  }
                });
              },
            ),
          IconButton(
            icon: const Icon(LucideIcons.download, color: Colors.white),
            tooltip: 'Export Data',
            onPressed: () {
              final titles = ['Data User', 'Data User Pending', 'Data Staff'];
              final types = ['user', 'verification_history', 'staff'];
              ExportService.exportData(
                context,
                titles[_tabController.index],
                types[_tabController.index],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Direktori'),
            Tab(text: 'Verifikasi'),
            Tab(text: 'Staff'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari user, email, atau NIP...',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
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
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.adminColor.withAlpha(26), // Light purple
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.filter),
                    color: AppTheme.adminColor,
                    onPressed: _showFilterModal,
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                UserDirectoryPage(
                  searchQuery: _searchQuery,
                  filters: _tabFilters[0],
                ),
                UserVerificationPage(
                  searchQuery: _searchQuery,
                  filters: _tabFilters[1],
                ),
                StaffManagementPage(
                  key: ValueKey(_staffRefreshKey),
                  searchQuery: _searchQuery,
                  shouldOpenAddDialog: widget.action == 'add',
                  filters: _tabFilters[2],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    final index = _tabController.index;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        index: index,
        currentFilters: Map.from(_tabFilters[index]),
        onApply: (newFilters) {
          setState(() {
            _tabFilters[index] = newFilters;
          });
        },
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final int index;
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApply;

  const _FilterBottomSheet({
    required this.index,
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.index == 0) ...[
            _buildDropdown(
              'Role User',
              'role',
              ['Semua', 'Pelapor', 'Teknisi', 'PJ Gedung', 'Supervisor', 'Admin'],
            ),
            const SizedBox(height: 16),
            _buildDropdown('Status', 'status', ['Semua', 'Aktif', 'Nonaktif']),
          ] else if (widget.index == 1) ...[
            _buildDropdown(
              'Departemen',
              'department',
              ['Semua', 'Teknik Komputer', 'Elektro', 'Sipil', 'Mesin'],
            ),
          ] else if (widget.index == 2) ...[
            _buildDropdown(
              'Role Staff',
              'role',
              ['Semua', 'Supervisor', 'PJ Gedung', 'Teknisi', 'Admin'],
            ),
            const SizedBox(height: 16),
            _buildDropdown('Status', 'status', ['Semua', 'Aktif', 'Nonaktif']),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_filters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.adminColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Terapkan Filter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String key, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filters[key] ?? items.first,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() => _filters[key] = value);
              },
            ),
          ),
        ),
      ],
    );
  }
}
