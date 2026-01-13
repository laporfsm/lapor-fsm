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
            // 1. Header Image Section (Mimic Damkar Header)
            Stack(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=2070&auto=format&fit=crop'), // Campus/Building Image
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lapor FSM",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Fakultas Sains & Matematika",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      // Undip Logo Placeholder
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(LucideIcons.graduationCap, color: Colors.white),
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
                   context.push('/create-report', extra: {
                    'category': 'Emergency',
                    'isEmergency': true,
                  });
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
                  const Text(
                    "Laporan Non-Darurat",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Gap(16),
                  _buildMenuGrid(context),
                  const Gap(24),
                  const Text(
                    "Info Terkini",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      bottomNavigationBar: _BottomNav(),
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
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (menu['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(menu['icon'] as IconData, color: menu['color'] as Color),
              ),
              const Gap(8),
              Text(
                menu['label'] as String,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPublicFeed() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        return Container(
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  // Mock Image
                   image: const DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage("https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&auto=format&fit=crop"), 
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Infrastruktur",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      "Lampu Koridor Kedip",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Gap(2),
                    const Text(
                      "Gedung A, Lt 2",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.push('/feed');
            break;
          case 2:
            context.push('/history');
            break;
          case 3:
            // Profile - TODO
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: "Beranda"),
        BottomNavigationBarItem(icon: Icon(LucideIcons.newspaper), label: "Feed"),
        BottomNavigationBarItem(icon: Icon(LucideIcons.fileText), label: "Aktivitas"),
        BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: "Profil"),
      ],
    );
  }
}
