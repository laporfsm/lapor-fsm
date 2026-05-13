import 'dart:async';
import 'package:flutter/material.dart';

class RealtimeTimerLabel extends StatefulWidget {
  final DateTime createdAt;
  final DateTime? pausedAt;
  final int totalPausedDurationSeconds;
  final TextStyle style;
  final Color color;

  const RealtimeTimerLabel({
    super.key,
    required this.createdAt,
    this.pausedAt,
    this.totalPausedDurationSeconds = 0,
    required this.style,
    required this.color,
  });

  @override
  State<RealtimeTimerLabel> createState() => _RealtimeTimerLabelState();
}

class _RealtimeTimerLabelState extends State<RealtimeTimerLabel> {
  Timer? _timer;
  late Duration _currentDuration;

  @override
  void initState() {
    super.initState();
    _calculateDuration();
    // Update every second for a smooth "running clock" feel.
    // If performance is an issue, this could be changed to every minute.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateDuration();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant RealtimeTimerLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.createdAt != oldWidget.createdAt ||
        widget.pausedAt != oldWidget.pausedAt ||
        widget.totalPausedDurationSeconds != oldWidget.totalPausedDurationSeconds) {
      _calculateDuration();
    }
  }

  void _calculateDuration() {
    final now = DateTime.now();
    final rawDuration = now.difference(widget.createdAt);
    
    // If currently paused, subtract the time since pause started
    final currentPauseDuration = widget.pausedAt != null
        ? now.difference(widget.pausedAt!)
        : Duration.zero;

    final totalPause =
        Duration(seconds: widget.totalPausedDurationSeconds) + currentPauseDuration;

    _currentDuration = rawDuration - totalPause;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    // If duration is negative (due to clock skew), just show 00:00
    if (duration.isNegative) {
      return '00:00';
    }

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
    return Text(
      _formatDuration(_currentDuration),
      style: widget.style.copyWith(color: widget.color),
    );
  }
}
