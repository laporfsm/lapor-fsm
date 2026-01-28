import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/notification/data/notification_data.dart';

/// State class for Notifications
class NotificationState {
  final List<NotificationItem> items;
  final int unreadCount;

  const NotificationState({required this.items, required this.unreadCount});

  factory NotificationState.initial() {
    final initialItems = NotificationData.notifications;
    return NotificationState(
      items: initialItems,
      unreadCount: initialItems.where((n) => !n.isRead).length,
    );
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
  @override
  NotificationState build() {
    return NotificationState.initial(); // Initialize state
  }

  /// Mark a single notification as read
  void markAsRead(String id) {
    final newItems = state.items.map((item) {
      if (item.id == id) {
        return NotificationItem(
          id: item.id,
          title: item.title,
          message: item.message,
          time: item.time,
          isRead: true,
          type: item.type,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: newItems);
  }

  /// Mark ALL notifications as read
  void markAllAsRead() {
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
  }

  /// Delete a notification
  void delete(String id) {
    final newItems = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: newItems);
  }

  /// Delete ALL notifications
  void deleteAll() {
    state = state.copyWith(items: []);
  }

  /// Add a new notification
  void add(NotificationItem item) {
    state = state.copyWith(items: [item, ...state.items]);
  }
}

/// Global Provider
final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );
