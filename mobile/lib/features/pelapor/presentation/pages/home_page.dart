import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Gap(24),
              _buildEmergencySection(),
              const Gap(24),
              Text(
                "Layanan Lainnya",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Gap(12),
              _buildMenuGrid(context),
              const Gap(24),
              Text(
                "Laporan Terbaru (Public Feed)",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Gap(12),
              _buildPublicFeed(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.map), label: "Peta"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.fileText), label: "Aktivitas"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selamat Datang, 👋",
              style: TextStyle(color: Colors.grey),
            ),
            const Gap(4),
            Text(
              "Sulhan Fuadi",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: const Icon(LucideIcons.bell, color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.siren, color: Colors.white, size: 48),
          const Gap(12),
          const Text(
            "DARURAT / EMERGENCY",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
          const Gap(8),
          const Text(
            "Tekan tombol ini jika Anda melihat Bahaya, Kebakaran, atau Kecelakaan.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Gap(16),
          ElevatedButton(
            onPressed: () {
              // Navigate to Create Report for Emergency
              GoRouter.of(context).push('/create-report', extra: {
                'category': 'Emergency',
                'isEmergency': true,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text("SOS - LAPOR SEKARANG"),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menus = [
      {'icon': LucideIcons.wrench, 'label': 'Infrastruktur', 'color': Colors.blue},
      {'icon': LucideIcons.trash2, 'label': 'Kebersihan', 'color': Colors.green},
      {'icon': LucideIcons.shieldAlert, 'label': 'Keamanan', 'color': Colors.orange},
      {'icon': LucideIcons.layoutGrid, 'label': 'Lainnya', 'color': Colors.purple},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return GestureDetector(
          onTap: () {
            GoRouter.of(context).push('/create-report', extra: {
              'category': menu['label'],
              'isEmergency': false,
            });
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(menu['icon'] as IconData, color: menu['color'] as Color),
              ),
              const Gap(8),
              Text(
                menu['label'] as String,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
      itemCount: 3,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage("https://via.placeholder.com/150"), // Placeholder
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
                      "AC Mati di Gedung E101",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Gap(2),
                    const Text(
                      "Gedung E, Lantai 1",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                  const Gap(2),
                  Text("2j lalu", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
