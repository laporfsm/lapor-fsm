import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data
  final List<Map<String, dynamic>> _emergencyCategories = [
    {'id': 1, 'name': 'Kebakaran', 'icon': '🔥', 'type': 'emergency'},
    {'id': 2, 'name': 'Kecelakaan Kerja', 'icon': '⚠️', 'type': 'emergency'},
    {'id': 3, 'name': 'K3 Lab', 'icon': '🧪', 'type': 'emergency'},
    {'id': 4, 'name': 'Tindak Kriminal', 'icon': '🚨', 'type': 'emergency'},
  ];

  final List<Map<String, dynamic>> _nonEmergencyCategories = [
    {'id': 5, 'name': 'Kelistrikan', 'icon': '⚡', 'type': 'non-emergency'},
    {'id': 6, 'name': 'Sanitasi / Air', 'icon': '🚿', 'type': 'non-emergency'},
    {
      'id': 7,
      'name': 'Sipil & Bangunan',
      'icon': '🏗️',
      'type': 'non-emergency',
    },
    {'id': 8, 'name': 'Fasilitas Umum', 'icon': '🪑', 'type': 'non-emergency'},
    {'id': 9, 'name': 'Kebersihan', 'icon': '🧹', 'type': 'non-emergency'},
    {'id': 10, 'name': 'Keamanan', 'icon': '🔒', 'type': 'non-emergency'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF059669),
          tabs: const [
            Tab(text: 'Darurat'),
            Tab(text: 'Non-Darurat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(_emergencyCategories, true),
          _buildCategoryList(_nonEmergencyCategories, false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Tambah Kategori'),
      ),
    );
  }

  Widget _buildCategoryList(
    List<Map<String, dynamic>> categories,
    bool isEmergency,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.tag, size: 64, color: Colors.grey.shade300),
            const Gap(16),
            Text(
              'Belum ada kategori',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = categories.removeAt(oldIndex);
          categories.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        return _buildCategoryCard(
          categories[index],
          isEmergency,
          key: ValueKey(categories[index]['id']),
        );
      },
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
    bool isEmergency, {
    Key? key,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isEmergency
            ? Border.all(color: AppTheme.emergencyColor.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isEmergency
                ? AppTheme.emergencyColor.withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              category['icon'] ?? '📌',
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          category['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isEmergency ? 'Kategori Darurat' : 'Kategori Non-Darurat',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showAddEditDialog(category),
              icon: const Icon(LucideIcons.pencil, size: 18),
              color: Colors.blue,
            ),
            IconButton(
              onPressed: () => _confirmDelete(category),
              icon: const Icon(LucideIcons.trash2, size: 18),
              color: Colors.red,
            ),
            const Icon(LucideIcons.gripVertical, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(Map<String, dynamic>? category) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final iconController = TextEditingController(text: category?['icon'] ?? '');
    String selectedType = category?['type'] ?? 'non-emergency';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(isEditing ? 'Edit Kategori' : 'Tambah Kategori Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori',
                    prefixIcon: Icon(LucideIcons.tag),
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon (Emoji)',
                    prefixIcon: Icon(LucideIcons.smile),
                    hintText: 'Contoh: 🔥',
                  ),
                ),
                const Gap(16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe',
                    prefixIcon: Icon(LucideIcons.alertTriangle),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'emergency',
                      child: Text('Darurat'),
                    ),
                    DropdownMenuItem(
                      value: 'non-emergency',
                      child: Text('Non-Darurat'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Call API
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Kategori berhasil diupdate'
                          : 'Kategori berhasil ditambahkan',
                    ),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kategori?'),
        content: Text(
          'Kategori "${category['name']}" akan dihapus. Kategori yang sedang digunakan tidak dapat dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Call API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kategori berhasil dihapus'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
