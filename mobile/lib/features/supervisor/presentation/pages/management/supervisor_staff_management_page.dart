import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';

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
  String _selectedFilter = 'Semua';

  // Mock Data
  final List<Map<String, dynamic>> _technicians = [
    {
      'id': '1',
      'name': 'Budi Santoso',
      'email': 'budi@undip.ac.id',
      'role': 'Teknisi Listrik',
      'isActive': true,
    },
    {
      'id': '2',
      'name': 'Andi Prasetyo',
      'email': 'andi@undip.ac.id',
      'role': 'Teknisi Sipil',
      'isActive': true,
    },
    {
      'id': '3',
      'name': 'Eko Wahyu',
      'email': 'eko@undip.ac.id',
      'role': 'Teknisi AC',
      'isActive': false,
    },
    {
      'id': '4',
      'name': 'Citra Dewi',
      'email': 'citra@undip.ac.id',
      'role': 'Teknisi Jaringan',
      'isActive': true,
    },
  ];

  final List<Map<String, dynamic>> _pjGedung = [
    {
      'id': 'pj1',
      'name': 'Rina PJ Gedung',
      'email': 'pj_a@undip.ac.id',
      'role': 'PJ Gedung',
      'isActive': true,
      'location': 'Gedung A',
    },
    {
      'id': 'pj2',
      'name': 'Siti PJ Gedung',
      'email': 'pj_b@undip.ac.id',
      'role': 'PJ Gedung',
      'isActive': true,
      'location': 'Gedung B',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: ListView.separated(
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/supervisor/technicians/add'),
              icon: const Icon(LucideIcons.userPlus, color: Colors.white),
              label: const Text('Tambah Teknisi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.supervisorColor,
                foregroundColor: Colors.white, // White text/icon
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
          child: ListView.separated(
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
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'Aktif', 'Nonaktif', 'Listrik', 'Sipil'];
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
    final isActive = staff['isActive'] as bool;

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
                            ? staff['role']
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
                  if (isTechnician) {
                    await context.push(
                      '/supervisor/technicians/edit/${staff['id']}',
                    );
                  }
                  setState(() {});
                },
              ),
              const Gap(8),
              _buildActionButton(
                icon: isActive ? LucideIcons.userX : LucideIcons.userCheck,
                color: isActive ? Colors.red : Colors.green,
                onTap: () {
                  setState(() {
                    staff['isActive'] = !isActive;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isActive
                            ? 'Staff dinonaktifkan'
                            : 'Staff diaktifkan kembali',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
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
