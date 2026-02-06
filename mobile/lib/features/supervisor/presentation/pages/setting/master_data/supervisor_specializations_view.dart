import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/utils/icon_helper.dart';
import 'package:mobile/core/theme.dart';

class SupervisorSpecializationsView extends StatefulWidget {
  const SupervisorSpecializationsView({super.key});

  @override
  State<SupervisorSpecializationsView> createState() =>
      _SupervisorSpecializationsViewState();
}

class _SupervisorSpecializationsViewState
    extends State<SupervisorSpecializationsView> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _specializations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSpecializations();
  }

  Future<void> _fetchSpecializations() async {
    setState(() => _isLoading = true);
    final data = await reportService.getSpecializations();
    if (mounted) {
      setState(() {
        _specializations = data.toList();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredSpecs {
    if (_searchController.text.isEmpty) return _specializations;
    final query = _searchController.text.toLowerCase();
    return _specializations
        .where((s) => s['name'].toString().toLowerCase().contains(query))
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
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari spesialisasi...',
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
                : _filteredSpecs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _filteredSpecs.length,
                    itemBuilder: (context, index) =>
                        _buildSpecCard(_filteredSpecs[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSpecSheet(null),
        backgroundColor: AppTheme.supervisorColor,
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
            hasSearch ? LucideIcons.searchX : LucideIcons.wrench,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const Gap(16),
          Text(
            hasSearch ? 'Tidak ditemukan' : 'Belum ada spesialisasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(Map<String, dynamic> spec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSpecSheet(spec),
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
                    color: AppTheme.supervisorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      IconHelper.getIcon(spec['icon'] ?? 'wrench'),
                      color: AppTheme.supervisorColor,
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
                        spec['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (spec['description'] != null &&
                          spec['description'].toString().isNotEmpty) ...[
                        const Gap(2),
                        Text(
                          spec['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: LucideIcons.pencil,
                      color: const Color(0xFF3B82F6),
                      onTap: () => _showSpecSheet(spec),
                    ),
                    const Gap(8),
                    _ActionButton(
                      icon: LucideIcons.trash2,
                      color: const Color(0xFFEF4444),
                      onTap: () => _confirmDelete(spec),
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

  void _showSpecSheet(Map<String, dynamic>? spec) {
    final isEditing = spec != null;
    final nameController = TextEditingController(text: spec?['name'] ?? '');
    final descController = TextEditingController(
      text: spec?['description'] ?? '',
    );
    String selectedIcon = spec?['icon'] ?? 'wrench';

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.supervisorColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? LucideIcons.pencil : LucideIcons.plus,
                          color: AppTheme.supervisorColor,
                          size: 20,
                        ),
                      ),
                      const Gap(12),
                      Text(
                        isEditing ? 'Edit Spesialisasi' : 'Tambah Spesialisasi',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),

                  const _Label('Nama Spesialisasi'),
                  const Gap(6),
                  TextField(
                    controller: nameController,
                    decoration: _inputDecor('Contoh: Teknisi Listrik'),
                  ),

                  const Gap(16),

                  const _Label('Keterangan (Opsional)'),
                  const Gap(6),
                  TextField(
                    controller: descController,
                    decoration: _inputDecor('Detail pekerjaan...'),
                  ),

                  const Gap(16),

                  const _Label('Pilih Icon'),
                  const Gap(10),
                  SizedBox(
                    height: 120,
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
                          onTap: () =>
                              setSheetState(() => selectedIcon = iconName),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.supervisorColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
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
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(context);

                            bool success;
                            if (isEditing) {
                              success = await reportService
                                  .updateSpecialization(
                                    int.parse(spec['id'].toString()),
                                    nameController.text.trim(),
                                    selectedIcon,
                                    descController.text.trim(),
                                  );
                            } else {
                              success = await reportService
                                  .createSpecialization(
                                    nameController.text.trim(),
                                    selectedIcon,
                                    descController.text.trim(),
                                  );
                            }

                            if (success) {
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'Berhasil diupdate'
                                        : 'Berhasil ditambahkan',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _fetchSpecializations();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.supervisorColor,
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

  void _confirmDelete(Map<String, dynamic> spec) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Spesialisasi?'),
        content: Text('Hapus "${spec['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              nav.pop();
              final res = await reportService.deleteSpecialization(
                int.parse(spec['id'].toString()),
              );
              if (res['success']) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Berhasil dihapus')),
                );
                _fetchSpecializations();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Gagal hapus'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
    );
  }
}

InputDecoration _inputDecor(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
  );
}
