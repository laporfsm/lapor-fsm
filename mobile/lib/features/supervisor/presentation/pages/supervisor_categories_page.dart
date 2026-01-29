import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/utils/icon_helper.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_shell_page.dart';

class SupervisorCategoriesPage extends StatefulWidget {
  const SupervisorCategoriesPage({super.key});

  @override
  State<SupervisorCategoriesPage> createState() =>
      _SupervisorCategoriesPageState();
}

class _SupervisorCategoriesPageState extends State<SupervisorCategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final data = await reportService.getCategories();
    if (mounted) {
      setState(() {
        _categories = data
            .where(
              (c) => !c['name'].toString().toLowerCase().contains('darurat'),
            )
            .toList();
        _isLoading = false;
      });
    }
  }

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
        leading: null,
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCategories.isEmpty
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
            color: Colors.black.withOpacity(0.05),
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
                    color: supervisorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      IconHelper.getIcon(category['icon'] ?? 'help-circle'),
                      color: supervisorColor,
                      size: 24,
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
                    // Protect "Lainnya" from deletion
                    if (category['name'].toString().toLowerCase() !=
                        'lainnya') ...[
                      const Gap(4),
                      _ActionButton(
                        icon: LucideIcons.trash2,
                        color: const Color(0xFFEF4444),
                        onTap: () => _confirmDelete(category),
                        tooltip: 'Hapus',
                      ),
                    ],
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
    String selectedIcon = category?['icon'] ?? 'help-circle';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
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
                          color: supervisorColor.withOpacity(0.1),
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

                  // Name Field
                  const Text(
                    'Nama Kategori (Maks 20 Karakter)',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const Gap(6),
                  TextField(
                    controller: nameController,
                    maxLength: 20,
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
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),

                  const Gap(16),

                  // Icon Picker
                  const Text(
                    'Pilih Icon',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const Gap(10),
                  SizedBox(
                    height: 150,
                    child: GridView.builder(
                      itemCount: IconHelper.availableIcons.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemBuilder: (ctx, index) {
                        final iconName = IconHelper.availableIcons[index];
                        final isSelected = iconName == selectedIcon;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedIcon = iconName;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? supervisorColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: supervisorColor, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              IconHelper.getIcon(iconName),
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
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
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;

                            // Close sheet first
                            Navigator.pop(context);

                            // Show loading
                            if (!mounted) return;
                            setState(() => _isLoading = true);

                            bool success;
                            if (isEditing) {
                              success = await reportService.updateCategory(
                                category['id'] is String
                                    ? int.parse(category['id'])
                                    : category['id'],
                                nameController.text.trim(),
                                selectedIcon,
                              );
                            } else {
                              success = await reportService.createCategory(
                                nameController.text.trim(),
                                selectedIcon,
                              );
                            }

                            if (mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'Kategori berhasil diupdate'
                                          : 'Kategori berhasil dibuat',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _fetchCategories();
                              } else {
                                setState(() => _isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gagal menyimpan kategori'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
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
          );
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hapus Kategori?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Gap(12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontFamily: 'PlusJakartaSans', // Ensure font matches app
                  ),
                  children: [
                    const TextSpan(
                      text: 'Apakah Anda yakin ingin menghapus kategori ',
                    ),
                    TextSpan(
                      text: '"${category['name']}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const TextSpan(
                      text: '?\nTindakan ini tidak dapat dibatalkan.',
                    ),
                  ],
                ),
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog
                        setState(
                          () => _isLoading = true,
                        ); // Show loading overlay

                        // Add small delay to prevent flickering if API is too fast
                        await Future.delayed(const Duration(milliseconds: 300));

                        try {
                          final result = await reportService.deleteCategory(
                            category['id'] is String
                                ? int.parse(category['id'])
                                : category['id'],
                          );

                          if (mounted) {
                            if (result['success']) {
                              // Optimistic update: Remove from list immediately
                              setState(() {
                                _categories.removeWhere(
                                  (c) => c['id'] == category['id'],
                                );
                                _isLoading = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kategori berhasil dihapus'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Fetch again just to be sure
                              _fetchCategories();
                            } else {
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ??
                                        'Gagal menghapus kategori',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
