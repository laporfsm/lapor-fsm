import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/core/theme.dart';

/// Clickable stat card for dashboard grids.
/// Shows icon, value, and label with tap navigation.
class StatGridCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;

  const StatGridCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: compact ? 20 : 24),
            Gap(compact ? 6 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Gap(compact ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Status badge card for dashboard status row.
/// Compact clickable stat showing count and label.
class StatusBadgeCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const StatusBadgeCard({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BouncingButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 18,
                ),
              ),
              const Gap(2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Period stat row widget for dashboard.
/// Shows today, week, month stats in a row.
class PeriodStatsRow extends StatelessWidget {
  final int todayCount;
  final int weekCount;
  final int monthCount;
  final Function(String period)? onTap;

  const PeriodStatsRow({
    super.key,
    required this.todayCount,
    required this.weekCount,
    required this.monthCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatGridCard(
            label: 'Hari Ini',
            value: todayCount.toString(),
            icon: Icons.today,
            color: Colors.blue,
            onTap: () => onTap?.call('today'),
          ),
        ),
        const Gap(12),
        Expanded(
          child: StatGridCard(
            label: 'Minggu Ini',
            value: weekCount.toString(),
            icon: Icons.date_range,
            color: Colors.green,
            onTap: () => onTap?.call('week'),
          ),
        ),
        const Gap(12),
        Expanded(
          child: StatGridCard(
            label: 'Bulan Ini',
            value: monthCount.toString(),
            icon: Icons.calendar_month,
            color: Colors.orange,
            onTap: () => onTap?.call('month'),
          ),
        ),
      ],
    );
  }
}

/// Status stats row for dashboard.
/// Shows Diproses, Penanganan, OnHold, Selesai in a grid and Recalled full width.
class StatusStatsRow extends StatelessWidget {
  final int diprosesCount;
  final int penangananCount;
  final int onHoldCount;
  final int selesaiCount;
  final int recalledCount;
  final Function(String status)? onTap;

  const StatusStatsRow({
    super.key,
    required this.diprosesCount,
    required this.penangananCount,
    required this.onHoldCount,
    required this.selesaiCount,
    this.recalledCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Laporan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Icon(
                Icons.insights_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          const Gap(16),
          // Row of 4 items
          Row(
            children: [
              _StatusBox(
                label: 'Diproses',
                count: diprosesCount,
                statusKey: 'diproses',
                onTap: () => onTap?.call('diproses'),
              ),
              const Gap(8),
              _StatusBox(
                label: 'Penanganan',
                count: penangananCount,
                statusKey: 'penanganan',
                onTap: () => onTap?.call('penanganan'),
              ),
              const Gap(8),
              _StatusBox(
                label: 'On Hold',
                count: onHoldCount,
                statusKey: 'onHold',
                onTap: () => onTap?.call('onHold'),
              ),
              const Gap(8),
              _StatusBox(
                label: 'Selesai',
                count: selesaiCount,
                statusKey: 'selesai',
                onTap: () => onTap?.call('selesai'),
              ),
            ],
          ),
          // Full width Recalled
          const Gap(8),
          _StatusBox(
            label: 'Recalled oleh Supervisor',
            count: recalledCount,
            statusKey: 'recalled',
            isFullWidth: true,
            onTap: () => onTap?.call('recalled'),
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String label;
  final int count;
  final String statusKey;
  final bool isFullWidth;
  final VoidCallback? onTap;

  const _StatusBox({
    required this.label,
    required this.count,
    required this.statusKey,
    this.isFullWidth = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStatusColor(statusKey);
    final content = BouncingButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: isFullWidth ? 16 : 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: isFullWidth
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.center,
          children: [
            if (!isFullWidth)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            else ...[
              Row(
                children: [
                  Icon(
                    AppTheme.getStatusIcon(statusKey),
                    size: 16,
                    color: color,
                  ),
                  const Gap(8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isFullWidth) return content;
    return Expanded(child: content);
  }
}
