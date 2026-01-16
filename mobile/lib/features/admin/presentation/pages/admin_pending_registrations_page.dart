import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';


/// Admin Page for Verifying User Registrations (Non-UNDIP users)
class AdminPendingRegistrationsPage extends StatefulWidget {
  const AdminPendingRegistrationsPage({super.key});

  @override
  State<AdminPendingRegistrationsPage> createState() =>
      _AdminPendingRegistrationsPageState();
}

class _AdminPendingRegistrationsPageState
    extends State<AdminPendingRegistrationsPage> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data
  final List<Map<String, dynamic>> _pendingRegistrations = [
    {
      'id': 1,
      'name': 'Rudi Setiawan',
      'email': 'rudi.setiawan@gmail.com',
      'nimNip': '21120119140001',
      'phone': '081234567890',
      'address': 'Jl. Pemuda No. 123, Semarang',
      'registeredAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 2,
      'name': 'Sri Wahyuni',
      'email': 'sri.wahyuni@yahoo.com',
      'nimNip': '21120119140002',
      'phone': '081234567892',
      'address': 'Jl. Diponegoro No. 45, Semarang',
      'registeredAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'id': 3,
      'name': 'Bambang Pratama',
      'email': 'bambang.pratama@outlook.com',
      'nimNip': '21120119140003',
      'phone': '081234567894',
      'address': 'Jl. Sudirman No. 78, Semarang',
      'registeredAt': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  List<Map<String, dynamic>> get _filteredRegistrations {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _pendingRegistrations;
    return _pendingRegistrations.where((r) {
      return r['name'].toString().toLowerCase().contains(query) ||
          r['email'].toString().toLowerCase().contains(query);
    }).toList();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
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
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Verifikasi Pendaftaran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: const Color(0xFF059669),
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
                  hintText: 'Cari pendaftar...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(LucideIcons.search,
                      color: Colors.grey.shade400, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x,
                              color: Colors.grey.shade400, size: 18),
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
            child: _filteredRegistrations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRegistrations.length,
                    itemBuilder: (context, index) =>
                        _buildRegistrationCard(_filteredRegistrations[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.userCheck, size: 48, color: Colors.grey.shade300),
          const Gap(16),
          const Text(
            'Semua Terverifikasi!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(4),
          Text(
            'Tidak ada pendaftaran yang menunggu',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(Map<String, dynamic> registration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        registration['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      _formatTimeAgo(registration['registeredAt']),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  registration['email'],
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                const Gap(6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.clock,
                              size: 10, color: const Color(0xFFF59E0B)),
                          const Gap(4),
                          const Text(
                            'Menunggu Verifikasi',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    Icon(LucideIcons.creditCard,
                        size: 12, color: Colors.grey.shade400),
                    const Gap(4),
                    Text(
                      registration['nimNip'],
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _IconActionButton(
                  icon: LucideIcons.x,
                  color: const Color(0xFFEF4444),
                  tooltip: 'Tolak',
                  onTap: () => _showRejectSheet(registration),
                ),
                const Gap(10),
                _IconActionButton(
                  icon: LucideIcons.check,
                  color: const Color(0xFF22C55E),
                  tooltip: 'Setujui',
                  onTap: () => _approveRegistration(registration),
                ),
                const Gap(10),
                _IconActionButton(
                  icon: LucideIcons.eye,
                  color: const Color(0xFF3B82F6),
                  tooltip: 'Detail',
                  onTap: () => _showDetailSheet(registration),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _approveRegistration(Map<String, dynamic> registration) {
    setState(() {
      _pendingRegistrations.removeWhere((r) => r['id'] == registration['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${registration['name']} berhasil disetujui'),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRejectSheet(Map<String, dynamic> registration) {
    final reasonController = TextEditingController();

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
              const Text(
                'Tolak Pendaftaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              Text(
                'Berikan alasan penolakan untuk ${registration['name']}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const Gap(16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Contoh: Dokumen identitas tidak valid',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
              const Gap(16),
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
                        Navigator.pop(context);
                        setState(() {
                          _pendingRegistrations
                              .removeWhere((r) => r['id'] == registration['id']);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${registration['name']} ditolak'),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tolak'),
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

  void _showDetailSheet(Map<String, dynamic> registration) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registration['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          registration['email'],
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Info
              _InfoRow(
                icon: LucideIcons.creditCard,
                label: 'NIM/NIP',
                value: registration['nimNip'],
              ),
              const Gap(12),
              _InfoRow(
                icon: LucideIcons.phone,
                label: 'No. Telepon',
                value: registration['phone'],
              ),
              const Gap(12),
              _InfoRow(
                icon: LucideIcons.mapPin,
                label: 'Alamat',
                value: registration['address'],
              ),
              const Gap(12),
              _InfoRow(
                icon: LucideIcons.calendar,
                label: 'Waktu Daftar',
                value: _formatTimeAgo(registration['registeredAt']),
              ),
              const Gap(12),
              
              // Kartu Identitas
              Row(
                children: [
                  Icon(LucideIcons.contact, size: 18, color: Colors.grey.shade400),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kartu Identitas',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        GestureDetector(
                          onTap: () {
                             showDialog(
                               context: context,
                               builder: (ctx) => Dialog(
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                 child: Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Container(
                                       width: double.infinity,
                                       height: 250,
                                       decoration: BoxDecoration(
                                         color: Colors.grey.shade200,
                                         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                       ),
                                        child: const Center(
                                          child: Icon(LucideIcons.image, size: 64, color: Colors.grey),
                                        ),
                                     ),
                                     Padding(
                                       padding: const EdgeInsets.all(16),
                                       child: SizedBox(
                                         width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF059669),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: const Text('Tutup'),
                                          ),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             );
                          },
                          child: const Text(
                            'Lihat Foto',
                            style: TextStyle(
                              fontWeight: FontWeight.w500, 
                              fontSize: 14,
                              color: Color(0xFF3B82F6),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Gap(20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showRejectSheet(registration);
                      },
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _approveRegistration(registration);
                      },
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
