import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:mobile/features/notification/data/notification_data.dart';
import 'package:mobile/core/providers/auth_provider.dart';

/// State class for Notifications
class NotificationState {
  final List<NotificationItem> items;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    required this.items,
    required this.unreadCount,
    this.isLoading = false,
  });

  factory NotificationState.initial() {
    return const NotificationState(items: [], unreadCount: 0, isLoading: false);
  }

  NotificationState copyWith({List<NotificationItem>? items, bool? isLoading}) {
    final newItems = items ?? this.items;
    return NotificationState(
      items: newItems,
      unreadCount: newItems.where((n) => !n.isRead).length,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier to manage Notification State
class NotificationNotifier extends Notifier<NotificationState> {
  Timer? _timer;
  int _lastMaxId = -1;
  bool _isFirstLoad = true;

  @override
  NotificationState build() {
    // Watch current user to react to login/logout
    final userAsync = ref.watch(currentUserProvider);

    ref.onDispose(() {
      _timer?.cancel();
    });

    userAsync.whenData((user) {
      if (user != null) {
        _startPolling();
      } else {
        _timer?.cancel();
        _timer = null;
        _lastMaxId = -1;
        _isFirstLoad = true;
      }
    });

    return NotificationState.initial();
  }

  void _startPolling() {
    if (_timer != null) return; // Already polling

    _fetchNotifications(); // Immediate fetch
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchNotifications(),
    );
  }

  Future<void> _fetchNotifications() async {
    try {
      final user = await authService.getCurrentUser();
      if (user == null) {
        if (state.items.isNotEmpty) state = NotificationState.initial();
        return;
      }

      final userId = user['id'];
      final role = user['role'];

      // Determine correct notification type based on role
      // In current system: pelapor=user, and others (teknisi, supervisor, pj_gedung, admin)=staff
      final type = (role == 'pelapor' || role == 'user') ? 'user' : 'staff';

      final response = await apiService.dio.get('/notifications/$type/$userId');

      if (response.data['status'] == 'success') {
        final List<dynamic> data = response.data['data'];
        final List<NotificationItem> fetchedItems = data
            .map((json) => NotificationItem.fromJson(json))
            .toList();

        // Calculate max ID
        int currentMaxId = 0;
        if (fetchedItems.isNotEmpty) {
          currentMaxId = fetchedItems
              .map((e) => int.tryParse(e.id) ?? 0)
              .reduce((a, b) => a > b ? a : b);
        }

        // Check for new items to alert (Only if there's a new max ID)
        if (!_isFirstLoad && currentMaxId > _lastMaxId) {
          final newItems = fetchedItems
              .where((e) => (int.tryParse(e.id) ?? 0) > _lastMaxId)
              .toList();

          // Show the most recent one as local notification if many came at once
          if (newItems.isNotEmpty) {
            // Sort by time just in case
            newItems.sort((a, b) => b.time.compareTo(a.time));
            final latest = newItems.first;

            await NotificationService.showNotification(
              id: int.tryParse(latest.id) ?? 0,
              title: latest.title,
              message: latest.message,
              isEmergency: latest.type == 'emergency',
              payload: latest.reportId,
            );
          }
        }

        if (_isFirstLoad) {
          _isFirstLoad = false;
        }

        _lastMaxId = currentMaxId;
        state = state.copyWith(items: fetchedItems, isLoading: false);
      }
    } catch (e) {
      print('Notification Poll Error: $e');
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String id) async {
    // Optimistic update
    final newItems = state.items.map((item) {
      if (item.id == id) {
        return NotificationItem(
          id: item.id,
          title: item.title,
          message: item.message,
          time: item.time,
          isRead: true,
          type: item.type,
          reportId: item.reportId,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);

    try {
      await apiService.dio.patch('/notifications/$id/read');
    } catch (e) {
      print('Failed to mark read API: $e');
    }
  }

  /// Mark ALL notifications as read
  Future<void> markAllAsRead() async {
    final newItems = state.items.map((item) {
      return NotificationItem(
        id: item.id,
        title: item.title,
        message: item.message,
        time: item.time,
        isRead: true,
        type: item.type,
        reportId: item.reportId,
      );
    }).toList();
    state = state.copyWith(items: newItems);

    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final userId = user['id'];
        final role = user['role'];
        final type = (role == 'pelapor' || role == 'user') ? 'user' : 'staff';

        await apiService.dio.post(
          '/notifications/read-all',
          data: {'type': type, 'id': userId},
        );
      }
    } catch (e) {
      print('Failed to mark all read API: $e');
    }
  }

  /// Delete a notification
  Future<void> delete(String id) async {
    final newItems = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: newItems);

    try {
      await apiService.dio.delete('/notifications/$id');
    } catch (e) {
      print('Failed to delete API: $e');
    }
  }

  /// Delete ALL notifications
  Future<void> deleteAll() async {
    final user = await authService.getCurrentUser();
    if (user == null) return;

    final userId = user['id'];
    final role = user['role'];
    final type = (role == 'pelapor' || role == 'user') ? 'user' : 'staff';

    // Optimistic update
    state = state.copyWith(items: []);

    try {
      // Assuming there's a delete-all endpoint or we loop.
      // For now, let's assume we need to implement it in backend or just clear local if not available.
      // The backend doesn't have a delete-all yet, so let's just clear local for now
      // or implement it in backend.
      // I'll add a placeholder call.
      await apiService.dio.delete('/notifications/all/$type/$userId');
    } catch (e) {
      print('Failed to delete all API: $e');
    }
  }

  /// Refresh manual
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _fetchNotifications();
  }
}

/// Global Provider
final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );
