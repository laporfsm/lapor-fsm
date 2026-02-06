import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/features/supervisor/presentation/pages/dashboard/supervisor_shell_page.dart';

class SupervisorLocationsView extends StatefulWidget {
  const SupervisorLocationsView({super.key});

  @override
  State<SupervisorLocationsView> createState() =>
      _SupervisorLocationsViewState();
}

class _SupervisorLocationsViewState extends State<SupervisorLocationsView> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _buildings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBuildings();
  }

  Future<void> _fetchBuildings() async {
    setState(() => _isLoading = true);
    final data = await reportService.getLocations();
    if (mounted) {
      setState(() {
        _buildings = data;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredBuildings {
    if (_searchController.text.isEmpty) return _buildings;
    final query = _searchController.text.toLowerCase();
    return _buildings
        .where((b) => b['name'].toString().toLowerCase().contains(query))
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
                  hintText: 'Cari lokasi...',
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
                : _filteredBuildings.isEmpty
                ? _buildEmptyState(_searchController.text.isNotEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _filteredBuildings.length,
                    separatorBuilder: (_, __) => const Gap(10),
                    itemBuilder: (context, index) =>
                        _buildBuildingItem(_filteredBuildings[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBuildingSheet(null),
        backgroundColor: supervisorColor,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  // Data gedung FSM Default (from CreateReportPage)
  final List<String> _defaultBuildings = [
    'Gedung A',
    'Gedung B',
    'Gedung C',
    'Gedung D',
    'Gedung E',
    'Gedung F',
    'Gedung G',
    'Gedung H',
    'Gedung I',
    'Gedung J',
    'Gedung K',
    'Gedung L',
    'Parkiran Motor',
    'Parkiran Mobil',
    'Masjid',
    'Gedung Acintya Prasada',
    'Taman Rumah Kita',
    'Kantin',
    'Lainnya',
  ];

  Future<void> _importDefaults() async {
    setState(() => _isLoading = true);
    try {
      int successCount = 0;
      for (final buildingName in _defaultBuildings) {
        // Check if exists first? strict optimization omitted for speed, API might handle duplicates or just add.
        // Assuming API allows duplicates or we don't care for this simple import.
        final success = await reportService.createLocation(buildingName);
        if (success) successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengimpor $successCount lokasi default'),
          ),
        );
        _fetchBuildings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal import: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildEmptyState(bool hasSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.building, size: 64, color: Colors.grey.shade300),
          const Gap(16),
          Text(
            hasSearch ? 'Tidak ditemukan' : 'Belum ada data lokasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          if (!hasSearch) ...[
            const Gap(16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _importDefaults,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.downloadCloud, size: 16),
              label: Text(
                _isLoading ? 'Mengimpor...' : 'Import Lokasi Default',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: supervisorColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBuildingItem(Map<String, dynamic> building) {
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
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: supervisorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(LucideIcons.building, color: supervisorColor),
        ),
        title: Text(
          building['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                LucideIcons.pencil,
                size: 20,
                color: Colors.blue,
              ),
              onPressed: () => _showBuildingSheet(building),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.red),
              onPressed: () => _confirmDelete(building),
              tooltip: 'Hapus',
            ),
          ],
        ),
      ),
    );
  }

  void _showBuildingSheet(Map<String, dynamic>? building) {
    final isEditing = building != null;
    final nameController = TextEditingController(text: building?['name'] ?? '');

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: supervisorColor.withValues(alpha: 0.1),
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
                    isEditing ? 'Edit Lokasi' : 'Tambah Lokasi',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Gap(24),
              const Text(
                'Nama Lokasi',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const Gap(6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Gedung E / Taman',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
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
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        bool success;
                        if (isEditing) {
                          success = await reportService.updateLocation(
                            int.parse(building['id'].toString()),
                            nameController.text.trim(),
                          );
                        } else {
                          success = await reportService.createLocation(
                            nameController.text.trim(),
                          );
                        }

                        if (success) {
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Lokasi berhasil diupdate'
                                    : 'Lokasi berhasil ditambahkan',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _fetchBuildings();
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Gagal menyimpan lokasi'),
                              backgroundColor: Colors.red,
                            ),
                          );
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
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> building) {
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
                'Hapus Lokasi?',
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
                    fontFamily: 'PlusJakartaSans',
                  ),
                  children: [
                    const TextSpan(text: 'Yakin hapus lokasi '),
                    TextSpan(
                      text: '"${building['name']}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        nav.pop();

                        setState(() => _isLoading = true);

                        final result = await reportService.deleteLocation(
                          int.parse(building['id'].toString()),
                        );

                        if (result['success']) {
                          setState(() {
                            _buildings.removeWhere(
                              (b) => b['id'] == building['id'],
                            );
                            _isLoading = false;
                          });
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Lokasi berhasil dihapus'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          setState(() => _isLoading = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Gagal hapus'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.white),
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
