import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class SupervisorTechnicianListPage extends StatefulWidget {
  const SupervisorTechnicianListPage({super.key});

  @override
  State<SupervisorTechnicianListPage> createState() =>
      _SupervisorTechnicianListPageState();
}

class _SupervisorTechnicianListPageState
    extends State<SupervisorTechnicianListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  // Mock Data Updated to match Management Context
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Search Bar Section (No AppBar)
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
                final tech = _technicians[index];
                return _buildTechnicianCard(context, tech);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/supervisor/technicians/add');
          // Refresh logic here if needed
          setState(() {});
        },
        backgroundColor: AppTheme.supervisorColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.userPlus, color: Colors.white),
      ),
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

  Widget _buildTechnicianCard(BuildContext context, Map<String, dynamic> tech) {
    final isActive = tech['isActive'] as bool;

    return GestureDetector(
      onTap: () => context.push('/supervisor/technician/${tech['id']}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                        tech['name'],
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
                    tech['email'],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tech['role'], // e.g. "Teknisi Listrik" -> "Teknisi" tag
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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
                    // Prevent navigating to detail when clicking edit
                    await context.push(
                      '/supervisor/technicians/edit/${tech['id']}',
                    );
                    setState(() {});
                  },
                ),
                const Gap(8),
                _buildActionButton(
                  icon: isActive ? LucideIcons.userX : LucideIcons.userCheck,
                  color: isActive ? Colors.red : Colors.green,
                  onTap: () {
                    // Toggle Active Status
                    setState(() {
                      tech['isActive'] = !isActive;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isActive
                              ? 'Teknisi dinonaktifkan'
                              : 'Teknisi diaktifkan kembali',
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
