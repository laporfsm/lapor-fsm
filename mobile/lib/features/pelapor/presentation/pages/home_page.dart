import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/widgets/universal_report_card.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/utils/icon_helper.dart';
import 'package:mobile/features/notification/presentation/widgets/notification_fab.dart';

class HomePage extends ConsumerStatefulWidget {
  final void Function(int)? onTabSwitch;

  const HomePage({super.key, this.onTabSwitch});

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
      final response = await reportService.getPublicReports();
      final List<Map<String, dynamic>> reportsData =
          List<Map<String, dynamic>>.from(response['data'] ?? []);

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
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: const NotificationFab(
        backgroundColor: AppTheme.primaryColor,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              automaticallyImplyLeading: false,
              elevation: 0,
              title: innerBoxIsScrolled
                  ? Image.asset(
                      'assets/images/logo.png',
                      height: 32,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'Lapor FSM!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : null,
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Base Gradient Background
                    Container(
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
                    // 2. Decorative Patterns
                    Positioned(
                      top: -10,
                      left: -20,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 500,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withAlpha(25),
                                Colors.white.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 65,
                      left: -100,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 500,
                          height: 40,
                          color: Colors.white.withAlpha(12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      right: -50,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 300,
                          height: 40,
                          color: Colors.white.withAlpha(25),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: -40,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 200,
                          height: 20,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: -30,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 400,
                          height: 60,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    // 3. Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(40),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                LucideIcons.megaphone,
                                                color: Colors.white,
                                                size: 26,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                              const Gap(14),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Gap(2),
                                  Text(
                                    'Sistem Pelaporan Insiden & Fasilitas',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const Gap(1),
                                  Text(
                                    'FSM Universitas Diponegoro',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
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
                      const Gap(16),

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
                            onPressed: () {
                              // Navigate to Feed tab (index 1)
                              widget.onTabSwitch?.call(1);
                            },
                            child: const Text("Lihat Semua"),
                          ),
                        ],
                      ),
                      const Gap(8),
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
              ],
            ),
          ),
        ),
      ),
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
              // Outer vibrant glow
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              // Inner secondary glow
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: -4,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 4,
            ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = ((constraints.maxWidth - (3 * 12)) / 4)
            .floorToDouble();

        return Wrap(
          spacing: 12,
          runSpacing: 24,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: List.generate(
            shouldLimit ? maxItems : displayCategories.length,
            (index) {
              if (shouldLimit && index == maxItems - 1) {
                return SizedBox(
                  width: itemWidth,
                  child: BouncingButton(
                    onTap: _showAllCategoriesSheet,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.moreHorizontal,
                                color: Colors.black54,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                        const Gap(8),
                        const Text(
                          "Lihat Semua",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final category = displayCategories[index];
              final name = category['name'] as String;
              final iconStr = category['icon'] as String? ?? 'help-circle';

              return SizedBox(
                width: itemWidth,
                child: BouncingButton(
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.08,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconHelper.getIcon(iconStr),
                              color: AppTheme.primaryColor,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                          height: 1.1,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = ((constraints.maxWidth - (3 * 12)) / 4)
                        .floorToDouble();
                    return Wrap(
                      spacing: 12,
                      runSpacing: 24,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: List.generate(_categories.length, (index) {
                        final category = _categories[index];
                        final name = category['name'] as String;
                        final iconStr =
                            category['icon'] as String? ?? 'help-circle';

                        return SizedBox(
                          width: itemWidth,
                          child: BouncingButton(
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
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.08,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        IconHelper.getIcon(iconStr),
                                        color: AppTheme.primaryColor,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                    height: 1.1,
                                    letterSpacing: -0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
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
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentReports.length,
      separatorBuilder: (context, index) => const Gap(16),
      itemBuilder: (context, index) {
        final report = _recentReports[index];
        return UniversalReportCard(
          id: report.id,
          title: report.title,
          location: report.location,
          locationDetail: report.locationDetail,
          category: report.category,
          status: report.status,
          isEmergency: report.isEmergency,
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
