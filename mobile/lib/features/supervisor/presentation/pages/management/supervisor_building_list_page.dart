import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';

class SupervisorBuildingListPage extends StatefulWidget {
  const SupervisorBuildingListPage({super.key});

  @override
  State<SupervisorBuildingListPage> createState() =>
      _SupervisorBuildingListPageState();
}

class _SupervisorBuildingListPageState
    extends State<SupervisorBuildingListPage> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data - in real app this comes from API
  final List<Map<String, dynamic>> _buildings = [
    {'name': 'Gedung A', 'reports': 15, 'status': 'Critical'},
    {'name': 'Gedung B', 'reports': 8, 'status': 'Warning'},
    {'name': 'Gedung C', 'reports': 5, 'status': 'Safe'},
    {'name': 'Gedung D', 'reports': 2, 'status': 'Safe'},
    {'name': 'Gedung E', 'reports': 1, 'status': 'Safe'},
    {'name': 'Gedung F', 'reports': 0, 'status': 'Safe'},
    {'name': 'Gedung G', 'reports': 0, 'status': 'Safe'},
    {'name': 'Gedung H', 'reports': 0, 'status': 'Safe'},
    {'name': 'Kantin', 'reports': 3, 'status': 'Safe'},
  ];

  List<Map<String, dynamic>> _filteredBuildings = [];

  @override
  void initState() {
    super.initState();
    _filteredBuildings = _buildings;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredBuildings = _buildings
          .where(
            (building) => building['name'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Daftar Gedung'),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
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
                hintText: 'Cari gedung...',
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredBuildings.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final building = _filteredBuildings[index];
                return _buildBuildingItem(context, building);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingItem(
    BuildContext context,
    Map<String, dynamic> building,
  ) {
    final int reportCount = building['reports'];
    final bool isCritical = reportCount > 10;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          // Drill down to stats
          context.push(
            Uri(
              path: '/pj-gedung/statistics',
              queryParameters: {'buildingName': building['name']},
            ).toString(),
          );
        },
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCritical
                ? Colors.red.shade50
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCritical
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Icon(
            LucideIcons.building,
            color: isCritical ? Colors.red : AppTheme.primaryColor,
          ),
        ),
        title: Text(
          building['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$reportCount Laporan Aktif',
          style: TextStyle(
            color: isCritical ? Colors.red : Colors.grey.shade600,
            fontWeight: isCritical ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: const Icon(
          LucideIcons.chevronRight,
          size: 20,
          color: Colors.grey,
        ),
      ),
    );
  }
}
