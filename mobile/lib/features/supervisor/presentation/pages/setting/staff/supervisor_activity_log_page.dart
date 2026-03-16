import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/report_service.dart';

class SupervisorActivityLogPage extends StatefulWidget {
  final bool isEmbedded;

  const SupervisorActivityLogPage({super.key, this.isEmbedded = false});

  @override
  State<SupervisorActivityLogPage> createState() =>
      _SupervisorActivityLogPageState();
}

class _SupervisorActivityLogPageState extends State<SupervisorActivityLogPage>
    with SingleTickerProviderStateMixin {
   late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _technicianLogs = [];
  List<Map<String, dynamic>> _pjLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        reportService.getGlobalLogs(role: 'technician'),
        reportService.getGlobalLogs(role: 'pj'),
      ]);

      if (mounted) {
        setState(() {
          _technicianLogs = results[0];
          _pjLogs = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: widget.isEmbedded
            ? null
            : AppBar(
              title: const Text('Aktivitas & Log'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.isEmbedded) {
      return Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: 'Teknisi'),
                Tab(text: 'PJ Gedung'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogList(_technicianLogs),
                _buildLogList(_pjLogs),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas & Log'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: 'Teknisi'),
                Tab(text: 'PJ Gedung'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogList(_technicianLogs),
                _buildLogList(_pjLogs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.history, size: 64, color: Colors.grey.shade300),
            const Gap(16),
            Text(
              'Belum ada aktivitas',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        return _buildLogCard(logs[index]);
      },
    );
  }

   Widget _buildLogCard(Map<String, dynamic> log) {
    // Map backend action to human readable string
    String actionText = log['action'] ?? '';
    IconData icon = LucideIcons.info;
    Color color = Colors.grey;

    if (actionText == 'verified') {
      actionText = 'memverifikasi';
      icon = LucideIcons.checkCircle;
      color = Colors.green;
    } else if (actionText == 'handling') {
      actionText = 'menugaskan';
      icon = LucideIcons.userPlus;
      color = Colors.blue;
    } else if (actionText == 'accepted') {
      actionText = 'menerima tugas';
      icon = LucideIcons.wrench;
      color = Colors.orange;
    } else if (actionText == 'completed') {
      actionText = 'menyelesaikan';
      icon = LucideIcons.checkCheck;
      color = Colors.blue;
    } else if (actionText == 'approved') {
      actionText = 'menyetujui';
      icon = LucideIcons.award;
      color = Colors.orange;
    } else if (actionText == 'rejected') {
      actionText = 'menolak';
      icon = LucideIcons.xCircle;
      color = Colors.red;
    } else if (actionText == 'created') {
      actionText = 'membuat';
      icon = LucideIcons.plusCircle;
      color = Colors.purple;
    } else if (actionText == 'paused') {
      actionText = 'menunda';
      icon = LucideIcons.pauseCircle;
      color = Colors.orange;
    } else if (actionText == 'resumed') {
      actionText = 'melanjutkan';
      icon = LucideIcons.playCircle;
      color = Colors.blue;
    } else if (actionText == 'recalled') {
      actionText = 'menarik kembali';
      icon = LucideIcons.undo;
      color = Colors.red;
    }

    // Format time
    String timeStr = 'Baru saja';
    if (log['timestamp'] != null) {
      try {
        final date = DateTime.parse(log['timestamp']);
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0) {
          timeStr = '${diff.inDays} hari lalu';
        } else if (diff.inHours > 0) {
          timeStr = '${diff.inHours} jam lalu';
        } else if (diff.inMinutes > 0) {
          timeStr = '${diff.inMinutes} menit lalu';
        }
      } catch (e) {
        timeStr = '-';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log['actorName'] ?? 'Sistem',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        (log['actorRole'] ?? 'User').toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    children: [
                      TextSpan(text: actionText),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: log['reportTitle'] ?? 'laporan',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const Gap(4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
