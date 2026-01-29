import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';

class ReportTimerCard extends StatefulWidget {
  final DateTime createdAt;
  final bool isEmergency;

  const ReportTimerCard({
    super.key,
    required this.createdAt,
    required this.isEmergency,
  });

  @override
  State<ReportTimerCard> createState() => _ReportTimerCardState();
}

class _ReportTimerCardState extends State<ReportTimerCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateElapsed();
    });
  }

  void _updateElapsed() {
    if (mounted) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.createdAt);
      });
    }
  }

  String _formatElapsedTime(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return '${days}h ${hours}j ${minutes}m';
    } else if (hours > 0) {
      return '${hours}j ${minutes}m ${seconds}d';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}d';
    } else {
      return '$seconds detik';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverTarget = widget.isEmergency && _elapsed.inMinutes > 30;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isEmergency
              ? [const Color(0xFFDC2626), const Color(0xFFB91C1C)]
              : [AppTheme.primaryColor, const Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.isEmergency
                ? Colors.red.withValues(alpha: 0.3)
                : AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isEmergency ? LucideIcons.siren : LucideIcons.clock,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEmergency
                      ? 'Waktu Respon Darurat'
                      : 'Waktu Berjalan',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Gap(4),
                Text(
                  _formatElapsedTime(_elapsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.isEmergency ? 'Target: 30 menit' : 'Sejak dibuat',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              if (isOverTarget)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'MELEBIHI TARGET',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
