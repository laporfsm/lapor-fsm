import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_shell_page.dart'; // for supervisorColor

class SupervisorCategoriesPage extends StatefulWidget {
  const SupervisorCategoriesPage({super.key});

  @override
  State<SupervisorCategoriesPage> createState() =>
      _SupervisorCategoriesPageState();
}

class _SupervisorCategoriesPageState extends State<SupervisorCategoriesPage> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data shared with Admin
  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Kelistrikan', 'icon': '⚡', 'reportsCount': 23},
    {'id': 2, 'name': 'Sanitasi / Air', 'icon': '🚿', 'reportsCount': 18},
    {'id': 3, 'name': 'Sipil & Bangunan', 'icon': '🏗️', 'reportsCount': 45},
    {'id': 4, 'name': 'Fasilitas Umum', 'icon': '🪑', 'reportsCount': 32},
    {'id': 5, 'name': 'Kebersihan', 'icon': '🧹', 'reportsCount': 27},
    {'id': 6, 'name': 'Keamanan', 'icon': '🔒', 'reportsCount': 11},
    {'id': 7, 'name': 'Taman & Lingkungan', 'icon': '🌳', 'reportsCount': 8},
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchController.text.isEmpty) return _categories;
    final query = _searchController.text.toLowerCase();
    return _categories
        .where((c) => c['name'].toString().toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: supervisorColor,
        elevation: 0,
        leading: null, // Root tab, no back button
        title: const Text(
          'Kelola Kategori',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: supervisorColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari kategori...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: _filteredCategories.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) =>
                        _buildCategoryCard(_filteredCategories[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategorySheet(null),
        backgroundColor: supervisorColor,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? LucideIcons.searchX : LucideIcons.tag,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const Gap(16),
          Text(
            hasSearch ? 'Tidak ditemukan' : 'Belum ada kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const Gap(4),
          Text(
            hasSearch
                ? 'Coba kata kunci lain'
                : 'Tap + untuk menambah kategori',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCategorySheet(category),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: supervisorColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      category['icon'] ?? '📌',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const Gap(14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const Gap(4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.fileText,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const Gap(4),
                          Text(
                            '${category['reportsCount']} laporan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: LucideIcons.pencil,
                      color: const Color(0xFF3B82F6),
                      onTap: () => _showCategorySheet(category),
                      tooltip: 'Edit',
                    ),
                    const Gap(4),
                    _ActionButton(
                      icon: LucideIcons.trash2,
                      color: const Color(0xFFEF4444),
                      onTap: () => _confirmDelete(category),
                      tooltip: 'Hapus',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategorySheet(Map<String, dynamic>? category) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final iconController = TextEditingController(text: category?['icon'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: supervisorColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? LucideIcons.pencil : LucideIcons.plus,
                      color: supervisorColor,
                      size: 20,
                    ),
                  ),
                  const Gap(12),
                  Text(
                    isEditing ? 'Edit Kategori' : 'Tambah Kategori',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Gap(24),

              // Icon Field
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Icon',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(6),
                        TextField(
                          controller: iconController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                          decoration: InputDecoration(
                            hintText: '📌',
                            hintStyle: TextStyle(
                              fontSize: 24,
                              color: Colors.grey.shade300,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nama Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(6),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Kelistrikan',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        Navigator.pop(context);
                        setState(() {
                          if (isEditing) {
                            category['name'] = nameController.text.trim();
                            category['icon'] =
                                iconController.text.trim().isEmpty
                                ? '📌'
                                : iconController.text.trim();
                          } else {
                            _categories.add({
                              'id': DateTime.now().millisecondsSinceEpoch,
                              'name': nameController.text.trim(),
                              'icon': iconController.text.trim().isEmpty
                                  ? '📌'
                                  : iconController.text.trim(),
                              'reportsCount': 0,
                            });
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: supervisorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isEditing ? 'Simpan' : 'Tambah'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text(
              'Hapus Kategori?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _categories.remove(category));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
