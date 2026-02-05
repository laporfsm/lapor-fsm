import 'package:flutter/material.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';

import 'package:mobile/features/supervisor/data/services/supervisor_staff_service.dart';

class SupervisorStaffManagementPage extends StatefulWidget {
  const SupervisorStaffManagementPage({super.key});

  @override
  State<SupervisorStaffManagementPage> createState() =>
      _SupervisorStaffManagementPageState();
}

class _SupervisorStaffManagementPageState
    extends State<SupervisorStaffManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final SupervisorStaffService _staffService = SupervisorStaffService();

  String _selectedFilter = 'Semua';
  bool _isLoading = true;
  List<String> _specializations = [];

  List<Map<String, dynamic>> _technicians = [];
  List<Map<String, dynamic>> _pjGedung = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final techs = await _staffService.getTechnicians();
      final pjs = await _staffService.getPJGedung();
      final specs = await reportService.getSpecializations();

      if (mounted) {
        setState(() {
          _technicians = techs;
          _pjGedung = pjs;
          _specializations = specs.map((e) => e['name'].toString()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Teknisi'),
              Tab(text: 'PJ Gedung'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildTechnicianTab(), _buildPJGedungTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianTab() {
    return Column(
      children: [
        // Search & Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari teknisi...',
                prefixIcon: Icon(LucideIcons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        _buildFilterChips(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchData,
            child: _technicians.isEmpty
                ? const Center(child: Text('Belum ada teknisi'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _technicians.length,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) {
                      return _buildStaffCard(
                        context,
                        _technicians[index],
                        isTechnician: true,
                      );
                    },
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await context.push(
                  '/supervisor/technicians/add',
                );
                if (result == true) _fetchData();
              },
              icon: const Icon(LucideIcons.userPlus, color: Colors.white),
              label: const Text('Tambah Teknisi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.supervisorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPJGedungTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController, // Note: Sharing controller for now
              decoration: const InputDecoration(
                hintText: 'Cari PJ Gedung...',
                prefixIcon: Icon(LucideIcons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchData,
            child: _pjGedung.isEmpty
                ? const Center(child: Text('Belum ada PJ Gedung'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pjGedung.length,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) {
                      return _buildStaffCard(
                        context,
                        _pjGedung[index],
                        isTechnician: false,
                      );
                    },
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await context.push('/supervisor/pj-gedung/add');
                if (result == true) _fetchData();
              },
              icon: const Icon(LucideIcons.userPlus, color: Colors.white),
              label: const Text('Tambah PJ Gedung'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.supervisorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'Aktif', 'Nonaktif', ..._specializations];
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                },
                backgroundColor: Colors.white,
                selectedColor: AppTheme.supervisorColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.grey.shade300,
                  ),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStaffCard(
    BuildContext context,
    Map<String, dynamic> staff, {
    required bool isTechnician,
  }) {
    final isActive = (staff['isActive'] as bool?) ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      staff['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (!isActive) ...[
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Nonaktif',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(4),
                Text(
                  staff['email'],
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: !isTechnician
                        ? const Color(0xFFFFF7ED) // Orange-ish bg for PJ
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !isTechnician
                          ? const Color(0xFFFDBA74)
                          : Colors.blue.shade100,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        !isTechnician
                            ? LucideIcons.building
                            : LucideIcons.wrench,
                        size: 12,
                        color: !isTechnician
                            ? const Color(0xFFEA580C)
                            : Colors.blue.shade700,
                      ),
                      const Gap(4),
                      Text(
                        isTechnician
                            ? staff['specialization'] ?? 'Teknisi'
                            : staff['location'] ?? 'Area Umum',
                        style: TextStyle(
                          color: !isTechnician
                              ? const Color(0xFFEA580C)
                              : Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons
          Row(
            children: [
              _buildActionButton(
                icon: LucideIcons.pencil,
                color: Colors.blue,
                onTap: () async {
                  bool? result;
                  if (isTechnician) {
                    result = await context.push(
                      '/supervisor/technicians/edit/${staff['id']}',
                    );
                  } else {
                    result = await context.push(
                      '/supervisor/pj-gedung/edit/${staff['id']}',
                    );
                  }
                  if (result == true) _fetchData();
                },
              ),
              const Gap(8),
              _buildActionButton(
                icon: LucideIcons.trash2,
                color: Colors.red,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Staff'),
                      content: Text(
                        'Apakah Anda yakin ingin menghapus ${staff['name']}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    bool success;
                    if (isTechnician) {
                      success = await _staffService.deleteTechnician(
                        staff['id'].toString(),
                      );
                    } else {
                      success = await _staffService.deletePJGedung(
                        staff['id'].toString(),
                      );
                    }

                    if (!context.mounted) return;

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Staff berhasil dihapus')),
                      );
                      _fetchData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal menghapus staff')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
