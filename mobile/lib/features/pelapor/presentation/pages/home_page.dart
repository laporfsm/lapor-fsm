import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Image Section with Lapor FSM Branding
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                        const Color(0xFF1565C0),
                      ],
                    ),
                  ),
                ),
                // Background Pattern
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=2070&auto=format&fit=crop'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "UNIVERSITAS DIPONEGORO",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                              ),
                            ),
                            const Gap(8),
                            const Text(
                              "Lapor FSM!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Gap(4),
                            const Text(
                              "Sistem Pelaporan Fasilitas\nFakultas Sains & Matematika",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),
                      // Report Icon - Minimal & Compact
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.siren,
                          color: Color(0xFFDC2626),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Gap(40),

            // 2. Big Circular Panic Button (Mimic Damkar Button)
            Center(
              child: GestureDetector(
                onTap: () {
                   context.push('/emergency-report');
                },
                child: Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626), // Deep Red
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(LucideIcons.siren, color: Colors.white, size: 50),
                      Gap(8),
                      Text(
                        "LAPOR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "DARURAT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Gap(40),

            // 3. Grid Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Laporan Non-Darurat",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Pilih kategori untuk melaporkan kerusakan atau masalah fasilitas",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Gap(16),
                  _buildMenuGrid(context),
                  const Gap(24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Info Terkini",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Preview laporan terbaru",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/feed'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text("Lihat Semua"),
                      ),
                    ],
                  ),
                  const Gap(12),
                  _buildPublicFeed(),
                ],
              ),
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    // Kategori sesuai detail proyek: Maintenance & Kebersihan
    final menus = [
      // Maintenance
      {'icon': LucideIcons.building, 'label': 'Infrastruktur Kelas', 'color': Color(0xFF1E3A8A)},
      {'icon': LucideIcons.zap, 'label': 'Kelistrikan', 'color': Color(0xFFF59E0B)},
      {'icon': LucideIcons.hardHat, 'label': 'Sipil & Bangunan', 'color': Color(0xFF6366F1)},
      {'icon': LucideIcons.droplet, 'label': 'Sanitasi / Air', 'color': Color(0xFF0EA5E9)},
      // Kebersihan dan Ketertiban
      {'icon': LucideIcons.trash2, 'label': 'Kebersihan Area', 'color': Color(0xFF22C55E)},
      {'icon': LucideIcons.trees, 'label': 'Taman / Outdoor', 'color': Color(0xFF10B981)},
      {'icon': LucideIcons.moreHorizontal, 'label': 'Lain-lain', 'color': Colors.grey},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.65, // Adjusted for more vertical space
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return GestureDetector(
          onTap: () {
            context.push('/create-report', extra: {
              'category': menu['label'],
              'isEmergency': false,
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (menu['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(menu['icon'] as IconData, color: menu['color'] as Color, size: 22),
              ),
              const Gap(6),
              Flexible(
                child: Text(
                  menu['label'] as String,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPublicFeed() {
    // Mock data sesuai kategori dari detail proyek
    final feedItems = [
      {
        'title': 'AC Mati di Lab Komputer',
        'category': 'Kelistrikan',
        'building': 'Gedung G, Lt 2',
        'time': '10 menit lalu',
        'status': 'Penanganan',
        'color': Colors.orange,
      },
      {
        'title': 'Kebocoran Pipa Toilet',
        'category': 'Sanitasi / Air',
        'building': 'Gedung C, Lt 1',
        'time': '30 menit lalu',
        'status': 'Verifikasi',
        'color': Colors.blue,
      },
      {
        'title': 'Sampah Menumpuk',
        'category': 'Kebersihan Area',
        'building': 'Area Parkir',
        'time': '1 jam lalu',
        'status': 'Pending',
        'color': Colors.green,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: feedItems.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final item = feedItems[index];
        return GestureDetector(
          onTap: () => context.push('/feed'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                // Status Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.fileText, color: item['color'] as Color),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['category'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: item['color'] as Color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item['time'] as String,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        item['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Gap(2),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 12, color: Colors.grey.shade500),
                          const Gap(4),
                          Flexible(
                            child: Text(
                              item['building'] as String,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['status'] as String,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
