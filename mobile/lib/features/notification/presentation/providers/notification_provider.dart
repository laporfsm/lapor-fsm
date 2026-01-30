import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:mobile/features/notification/data/notification_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State class for Notifications
class NotificationState {
  final List<NotificationItem> items;
  final int unreadCount;

  const NotificationState({required this.items, required this.unreadCount});

  factory NotificationState.initial() {
    return const NotificationState(items: [], unreadCount: 0);
  }

  NotificationState copyWith({List<NotificationItem>? items}) {
    final newItems = items ?? this.items;
    return NotificationState(
      items: newItems,
      unreadCount: newItems.where((n) => !n.isRead).length,
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
    ref.onDispose(() {
      _timer?.cancel();
    });

    // Start polling after a short delay to ensure auth is ready
    Future.delayed(const Duration(seconds: 2), () => _startPolling());

    return NotificationState.initial();
  }

  void _startPolling() {
    _fetchNotifications(); // Immediate fetch
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchNotifications(),
    );
  }

  Future<void> _fetchNotifications() async {
    try {
      final user = await authService.getCurrentUser();
      if (user == null) return; // Not logged in

      final userId = user['id'];
      final role = user['role'];
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
          // Assumes ID is numeric incrementing
          currentMaxId = fetchedItems
              .map((e) => int.tryParse(e.id) ?? 0)
              .reduce((a, b) => a > b ? a : b);
        }

        // Check for new items to alert
        if (!_isFirstLoad && currentMaxId > _lastMaxId) {
          final newItems = fetchedItems.where(
            (e) => (int.tryParse(e.id) ?? 0) > _lastMaxId,
          );
          for (final item in newItems) {
            // Trigger Local Notification (Alert)
            await NotificationService.showNotification(
              id: int.tryParse(item.id) ?? 0,
              title: item.title,
              message: item.message,
              isEmergency: item.type == 'emergency',
            );
          }
        }

        if (_isFirstLoad) {
          _isFirstLoad = false;
        }

        _lastMaxId = currentMaxId;

        // Update state
        state = state.copyWith(items: fetchedItems);
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
          isRead: true, // Mark read
          type: item.type,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);

    // API Call
    try {
      await apiService.dio.patch('/notifications/$id/read');
    } catch (e) {
      // Revert if failed? For now just log
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

  /// Delete ALL notifications (Clear list visually)
  void deleteAll() {
    state = state.copyWith(items: []);
    // Note: API doesn't have delete all endpoint yet, so this is local only or requires iterative delete
  }

  /// Add a new notification (Manual)
  void add(NotificationItem item) {
    state = state.copyWith(items: [item, ...state.items]);
  }
}

/// Global Provider
final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );
