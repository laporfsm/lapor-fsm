import 'package:flutter/material.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/data/services/supervisor_staff_service.dart';

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

  // Service
  final _supervisorStaffService = SupervisorStaffService();

  List<Map<String, dynamic>> _technicians = [];
  List<String> _specializations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  Future<void> _fetchTechnicians() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final techs = await _supervisorStaffService.getTechnicians();
      final specs = await reportService.getSpecializations();
      if (mounted) {
        setState(() {
          _technicians = techs;
          _specializations = specs.map((e) => e['name'].toString()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data: $e';
          _isLoading = false;
        });
      }
    }
  }

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
                  hintText: 'Cari staff...',
                  prefixIcon: Icon(LucideIcons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) =>
                    setState(() {}), // Local filtering trigger
              ),
            ),
          ),

          _buildFilterChips(),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : RefreshIndicator(
                    onRefresh: _fetchTechnicians,
                    child: _technicians.isEmpty
                        ? const Center(child: Text('Belum ada teknisi'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTechnicians.length,
                            separatorBuilder: (context, index) => const Gap(12),
                            itemBuilder: (context, index) {
                              final tech = _filteredTechnicians[index];
                              return _buildTechnicianCard(context, tech);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          debugPrint('Navigating to Add Technician...');
          final result = await context.push('/supervisor/technicians/add');
          debugPrint('Returned from Add Technician. Result: $result');
          if (result == true) {
            debugPrint('Refreshing technicians list...');
            await _fetchTechnicians();
          }
        },
        backgroundColor: AppTheme.supervisorColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.userPlus, color: Colors.white),
      ),
    );
  }

  // Helper to filter locally
  List<Map<String, dynamic>> get _filteredTechnicians {
    return _technicians.where((tech) {
      final matchesSearch = tech['name'].toString().toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );

      if (!matchesSearch) return false;

      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Aktif') return tech['isActive'] == true;
      if (_selectedFilter == 'Nonaktif') return tech['isActive'] == false;

      // Filter by specialization/role
      final String role = tech['specialization'] ?? tech['role'] ?? '';
      return role.contains(_selectedFilter);
    }).toList();
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
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          tech['role'] == 'PJ Gedung' ||
                              tech['role'] == 'PJ Lokasi' ||
                              tech['role'] == 'pj_gedung' ||
                              tech['role'] == 'pj_location'
                          ? const Color(0xFFFFF7ED) // Orange-ish bg for PJ
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            tech['role'] == 'PJ Gedung' ||
                                tech['role'] == 'PJ Lokasi' ||
                                tech['role'] == 'pj_gedung' ||
                                tech['role'] == 'pj_location'
                            ? const Color(0xFFFDBA74)
                            : Colors.blue.shade100,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tech['role'] == 'PJ Gedung' ||
                                  tech['role'] == 'PJ Lokasi' ||
                                  tech['role'] == 'pj_gedung' ||
                                  tech['role'] == 'pj_location'
                              ? LucideIcons.mapPin
                              : LucideIcons.wrench,
                          size: 12,
                          color:
                              tech['role'] == 'PJ Gedung' ||
                                  tech['role'] == 'PJ Lokasi' ||
                                  tech['role'] == 'pj_gedung' ||
                                  tech['role'] == 'pj_location'
                              ? const Color(0xFFEA580C)
                              : Colors.blue.shade700,
                        ),
                        const Gap(4),
                        Text(
                          _getRoleDisplayName(tech),
                          style: TextStyle(
                            color: _getRoleColor(tech),
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
                    // Prevent navigating to detail when clicking edit
                    final result = await context.push(
                      '/supervisor/technicians/edit/${tech['id']}',
                    );
                    if (result == true) {
                      _fetchTechnicians();
                    }
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  String _getRoleDisplayName(Map<String, dynamic> tech) {
    if (tech['role'] == 'pj_gedung' ||
        tech['role'] == 'PJ Gedung' ||
        tech['role'] == 'pj_location' ||
        tech['role'] == 'PJ Lokasi') {
      return 'PJ Gedung';
    }
    // For technicians, prefer 'specialization'
    return tech['specialization'] ?? tech['role'] ?? 'Teknisi';
  }

  Color _getRoleColor(Map<String, dynamic> tech) {
    if (tech['role'] == 'pj_gedung' ||
        tech['role'] == 'PJ Gedung' ||
        tech['role'] == 'pj_location' ||
        tech['role'] == 'PJ Lokasi') {
      return const Color(0xFFEA580C);
    }
    return Colors.blue.shade700;
  }
}
