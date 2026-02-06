import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/notification/presentation/providers/notification_provider.dart';
import 'package:mobile/features/notification/presentation/widgets/notification_bottom_sheet.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/utils/icon_helper.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<Report> _recentReports = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchReports(), _fetchCategories()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await reportService.getCategories();
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(categories)
              .where(
                (c) => !c['name'].toString().toLowerCase().contains('darurat'),
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;

    try {
      final reportsData = await reportService.getPublicReports();
      if (mounted) {
        setState(() {
          _recentReports = reportsData
              .take(3)
              .map((json) => Report.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        child: CustomScrollView(
          slivers: [
            // 1. Header Section
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.8),
                          const Color(0xFF1565C0),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=2070&auto=format&fit=crop',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 25,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "UNIVERSITAS DIPONEGORO",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
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
                                "Sistem Pelaporan Fasilitas",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification Icon
                        _buildNotificationIcon(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Main Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Emergency Button
                  _buildEmergencyButton(),
                  const Gap(32),

                  // Menu Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Laporan Non-Darurat",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Pilih kategori untuk melaporkan masalah fasilitas",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Gap(16),
                        _buildMenuGrid(),
                        const Gap(32),

                        // Public Feed Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Info Terkini",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/feed'),
                              child: const Text("Lihat Semua"),
                            ),
                          ],
                        ),
                        const Gap(12),
                        _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _buildPublicFeed(),
                      ],
                    ),
                  ),
                  const Gap(80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Consumer(
      builder: (context, ref, child) {
        final unreadCount = ref.watch(notificationProvider).unreadCount;
        return BouncingButton(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => const NotificationBottomSheet(),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  LucideIcons.bell,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmergencyButton() {
    return Center(
      child: BouncingButton(
        scaleFactor: 0.90,
        onTap: () {
          context.push('/emergency-report');
        },
        child: Container(
          height: 160,
          width: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(LucideIcons.siren, color: Colors.white, size: 40),
              Gap(8),
              Text(
                "LAPOR",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "DARURAT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    if (_categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxItems = 8;
    // If categories <= 8, show all. If > 8, show 7 + "Lihat Semua"
    final shouldLimit = _categories.length > maxItems;
    final displayCategories = shouldLimit
        ? _categories.take(maxItems - 1).toList()
        : _categories;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: shouldLimit ? maxItems : displayCategories.length,
      itemBuilder: (context, index) {
        // "Lihat Semua" button
        if (shouldLimit && index == maxItems - 1) {
          return BouncingButton(
            onTap: _showAllCategoriesSheet,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.moreHorizontal,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
                const Gap(6),
                const Text(
                  "Lihat Semua",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          );
        }

        final category = displayCategories[index];
        final name = category['name'] as String;
        final iconStr = category['icon'] as String? ?? 'help-circle';

        return BouncingButton(
          onTap: () {
            context.push(
              '/create-report',
              extra: {
                'category': name,
                'isEmergency': false,
                'categoryId': category['id'].toString(),
              },
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconHelper.getIcon(iconStr),
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const Gap(6),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllCategoriesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              "Semua Kategori",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final name = category['name'] as String;
                  final iconStr = category['icon'] as String? ?? 'help-circle';

                  return BouncingButton(
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        '/create-report',
                        extra: {
                          'category': name,
                          'isEmergency': false,
                          'categoryId': category['id'].toString(),
                        },
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            IconHelper.getIcon(iconStr),
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicFeed() {
    if (_recentReports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            "Belum ada laporan publik terbaru",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentReports.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final report = _recentReports[index];
        return UniversalReportCard(
          id: report.id,
          title: report.title,
          location: report.location,
          locationDetail: report.locationDetail,
          category: report.category,
          status: report.status,
          reporterName: report.reporterName,
          elapsedTime: DateTime.now().difference(report.createdAt),
          showStatus: true,
          showTimer: true,
          onTap: () => context.push('/report-detail/${report.id}'),
        );
      },
    );
  }
}
