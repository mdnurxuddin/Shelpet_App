import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/user_provider.dart';

class NotificationState {
  final int unreadCount;
  NotificationState({this.unreadCount = 0});
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState());

  void updateCount(int count) {
    state = NotificationState(unreadCount: count);
  }

  Future<void> checkUnread(int userId) async {
    final notifs = await ApiService.getNotifications(userId);
    final unread = notifs.where((n) => n['is_read'] == "0").length;
    state = NotificationState(unreadCount: unread);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
