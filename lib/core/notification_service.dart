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

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
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
    print("Notification engine started...");
    
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
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
            if (notifs.isNotEmpty) {
              ref.read(notificationProvider.notifier).updateCount(notifs.length);
              for (var n in notifs) {
                final int notifId = int.tryParse(n['id'].toString()) ?? DateTime.now().millisecondsSinceEpoch % 100000;
                final String type = n['type'] ?? 'alert';
                final String title = type == 'rescue_alert' ? "🚨 EMERGENCY RESCUE" : "ShelPet Alert";
                
                await showNotification(notifId, title, n['message']);
                
                // Mark as read immediately to avoid duplicate popups
                await http.post(Uri.parse("${ApiService.baseUrl}/notifications/mark_read.php"), body: jsonEncode({"id": n['id']}));
              }
            } else {
              ref.read(notificationProvider.notifier).updateCount(0);
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
