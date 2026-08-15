import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelpet/core/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shelpet/core/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static Timer? _timer;

  static final Set<int> _shownNotificationIds = {};

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("Notification clicked: ${details.payload}");
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'shelpet_high_importance', 
      'ShelPet Critical Alerts',
      description: 'Urgent notifications for rescues and community updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(channel);
    try {
      await androidImplementation?.requestNotificationsPermission();
    } catch (_) {}
  }

  static Future<void> showNotification(int id, String title, String body, {String? payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'shelpet_high_importance', 
      'ShelPet Critical Alerts',
      channelDescription: 'Urgent notifications for rescues and community updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF0056B3),
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics
    );
    
    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics, payload: payload);
  }

  static void startPolling(int userId, WidgetRef ref) {
    _timer?.cancel();
    print("Notification engine started for user $userId...");
    
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      final prefs = await SharedPreferences.getInstance();
      bool isEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!isEnabled) return;

      try {
        final url = "${ApiService.baseUrl}/notifications/get_notifications.php?user_id=$userId&unread_only=true";
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == true) {
            List<dynamic> notifs = data['data'] ?? [];
            ref.read(notificationProvider.notifier).updateCount(notifs.length);

            for (var n in notifs) {
              final int notifId = int.tryParse(n['id'].toString()) ?? DateTime.now().millisecondsSinceEpoch % 100000;
              if (!_shownNotificationIds.contains(notifId)) {
                _shownNotificationIds.add(notifId);
                final String type = n['type'] ?? 'alert';
                
                String title = "ShelPet Alert 🐾";
                if (type == 'rescue_alert') {
                  title = "🚨 EMERGENCY RESCUE";
                } else if (type == 'reaction') {
                  title = "❤️ New Reaction";
                } else if (type == 'comment') {
                  title = "💬 New Comment";
                } else if (type == 'post') {
                  title = "🐾 New Post";
                }

                await showNotification(notifId, title, n['message'] ?? 'New notification');
              }
            }
          }
        }
      } catch (e) {
        print("Polling Error: $e");
      }
    });
  }

  static void stopPolling() {
    _timer?.cancel();
  }
}
