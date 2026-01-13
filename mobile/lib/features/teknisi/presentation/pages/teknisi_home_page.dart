import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

class TeknisiHomePage extends StatefulWidget {
  const TeknisiHomePage({super.key});

  @override
  State<TeknisiHomePage> createState() => _TeknisiHomePageState();
}

class _TeknisiHomePageState extends State<TeknisiHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;

  // Mock data - will be replaced with API calls
  // Timer starts from when report was CREATED (createdAt), not when technician starts handling
  final List<Map<String, dynamic>> _pendingReports = [
    {
      'id': 1,
      'title': 'AC Mati di Lab Komputer',
      'category': 'Kelistrikan',
      'building': 'Gedung G, Lt 2',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 10)),
      'isEmergency': false,
      'reporterName': 'Ahmad Fauzi',
      'reporterPhone': '08123456789',
    },
    {
      'id': 2,
      'title': 'Kebocoran Pipa Toilet',
      'category': 'Sanitasi / Air',
      'building': 'Gedung C, Lt 1',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
      'isEmergency': false,
      'reporterName': 'Siti Aminah',
      'reporterPhone': '08234567890',
    },
    {
      'id': 3,
      'title': 'Kecelakaan di Lab Kimia',
      'category': 'K3 Lab',
      'building': 'Gedung D, Lt 3',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 2)),
      'isEmergency': true,
      'reporterName': 'Budi Santoso',
      'reporterPhone': '08345678901',
    },
  ];

  final List<Map<String, dynamic>> _myReports = [
    {
      'id': 4,
      'title': 'Lampu Koridor Mati',
      'category': 'Kelistrikan',
      'building': 'Gedung A, Lt 1',
      'status': 'penanganan',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 45)),
      'startedAt': DateTime.now().subtract(const Duration(minutes: 15)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Start real-time timer that updates every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Custom App Bar with gradient
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        Color(0xFF3B82F6), // Lighter blue
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  LucideIcons.wrench,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const Gap(12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dashboard Teknisi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Lapor FSM - UP2TI',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    context.push('/teknisi/profile'),
                                icon: const Icon(
                                  LucideIcons.user,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.inbox, size: 18),
                        const Gap(8),
                        Text('Masuk (${_pendingReports.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.clock, size: 18),
                        const Gap(8),
                        Text('Dikerjakan (${_myReports.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Pending Reports
            _buildPendingReportsList(),
            // Tab 2: My Active Reports
            _buildMyReportsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingReportsList() {
    if (_pendingReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.checkCircle,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const Gap(16),
            Text(
              'Tidak ada laporan baru',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh data from API
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingReports.length,
        itemBuilder: (context, index) {
          final report = _pendingReports[index];
          return _buildReportCard(report, isPending: true);
        },
      ),
    );
  }

  Widget _buildMyReportsList() {
    if (_myReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clipboard, size: 64, color: Colors.grey.shade300),
            const Gap(16),
            Text(
              'Tidak ada laporan yang sedang dikerjakan',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myReports.length,
      itemBuilder: (context, index) {
        final report = _myReports[index];
        return _buildReportCard(report, isPending: false);
      },
    );
  }

  Widget _buildReportCard(
    Map<String, dynamic> report, {
    required bool isPending,
  }) {
    final bool isEmergency = report['isEmergency'] ?? false;
    final Color statusColor = isEmergency
        ? AppTheme.emergencyColor
        : AppTheme.primaryColor;

    // Calculate elapsed time from when report was CREATED
    final DateTime createdAt = report['createdAt'] as DateTime;
    final Duration elapsed = DateTime.now().difference(createdAt);

    return GestureDetector(
      onTap: () {
        context.push('/teknisi/report/${report['id']}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isEmergency
              ? Border.all(color: AppTheme.emergencyColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isEmergency
                  ? AppTheme.emergencyColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Banner
            if (isEmergency)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.emergencyColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      color: Colors.white,
                      size: 16,
                    ),
                    Gap(6),
                    Text(
                      'DARURAT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Timer (REAL-TIME from createdAt)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          report['category'],
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Real-time timer showing elapsed time since creation
                      _buildTimer(elapsed, isEmergency: isEmergency),
                    ],
                  ),
                  const Gap(10),

                  // Title
                  Text(
                    report['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Gap(8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          report['building'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (isPending) ...[
                    const Gap(8),
                    // Reporter info
                    Row(
                      children: [
                        Icon(
                          LucideIcons.user,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const Gap(6),
                        Text(
                          report['reporterName'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(12),
                        Icon(
                          LucideIcons.phone,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const Gap(6),
                        Text(
                          report['reporterPhone'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Gap(12),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/teknisi/report/${report['id']}');
                      },
                      icon: Icon(
                        isPending
                            ? LucideIcons.eye
                            : LucideIcons.clipboardCheck,
                        size: 18,
                      ),
                      label: Text(isPending ? 'Lihat Detail' : 'Selesaikan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPending
                            ? AppTheme.primaryColor
                            : const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer(Duration elapsed, {bool isEmergency = false}) {
    // Color based on urgency - if elapsed time is long, show warning color
    Color timerColor = AppTheme.secondaryColor;
    if (elapsed.inMinutes >= 30) {
      timerColor = Colors.red;
    } else if (elapsed.inMinutes >= 15) {
      timerColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer, size: 14, color: timerColor),
          const Gap(4),
          Text(
            _formatDuration(elapsed),
            style: TextStyle(
              color: timerColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
