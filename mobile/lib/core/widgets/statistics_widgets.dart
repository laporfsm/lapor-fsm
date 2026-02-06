import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StatsSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets? padding;

  const StatsSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Gap(16),
          child,
        ],
      ),
    );
  }
}

class StatsBarChartItem extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  final String? valueSuffix;
  final VoidCallback? onTap;

  const StatsBarChartItem({
    super.key,
    required this.label,
    required this.percentage,
    required this.color,
    this.valueSuffix,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: onTap != null ? Colors.blue : Colors.black,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(12),
              Text(
                valueSuffix ?? '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              if (onTap != null) ...[
                const Gap(8),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatsBigStatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;

  const StatsBigStatItem({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null) ...[Icon(icon, color: color, size: 20), const Gap(4)],
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class StatsTrendBar extends StatelessWidget {
  final String label;
  final double heightFactor;
  final Color activeColor;

  const StatsTrendBar({
    super.key,
    required this.label,
    required this.heightFactor,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: 100 * heightFactor.clamp(0.0, 1.0),
          decoration: BoxDecoration(
            color: heightFactor > 0.7
                ? activeColor
                : activeColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Gap(8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: heightFactor > 0.7
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class StatsTrendInfo extends StatelessWidget {
  final String label;
  final String value;
  final bool isUp;
  final bool emphasizeUpAsBad;

  const StatsTrendInfo({
    super.key,
    required this.label,
    required this.value,
    required this.isUp,
    this.emphasizeUpAsBad = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = isUp ? Colors.red : Colors.green;
    if (!emphasizeUpAsBad) {
      iconColor = isUp ? Colors.green : Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Gap(4),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Gap(4),
            Icon(
              isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              size: 16,
              color: iconColor,
            ),
          ],
        ),
      ],
    );
  }
}
