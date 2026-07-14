import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: user == null 
        ? const Center(child: Text('Please login to see notifications'))
        : FutureBuilder<List<dynamic>>(
            future: ApiService.getNotifications(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: ShelPetTheme.textMuted.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('No notifications yet', style: TextStyle(color: ShelPetTheme.textMuted)),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return _buildNotificationTile(context, n);
                },
              );
            },
          ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, dynamic n) {
    IconData icon = Icons.notifications;
    Color color = ShelPetTheme.primaryAccent;

    if (n['type'] == 'rescue_alert') {
      icon = Icons.emergency_share;
      color = Colors.redAccent;
    } else if (n['type'] == 'message') {
      icon = Icons.chat_bubble_rounded;
      color = Colors.blueAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: n['is_read'] == "0" ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: n['is_read'] == "0" ? color.withOpacity(0.2) : Colors.black.withOpacity(0.03)),
      ),
      child: ListTile(
        onTap: () {
           // Handle navigation based on type
           if (n['post_id'] != null) {
              // Maybe go to post details
           }
        },
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          n['message'] ?? '',
          style: TextStyle(
            fontSize: 14, 
            fontWeight: n['is_read'] == "0" ? FontWeight.bold : FontWeight.normal,
            color: ShelPetTheme.textPrimary
          ),
        ),
        subtitle: Text(
          n['created_at'] ?? '',
          style: const TextStyle(fontSize: 11, color: ShelPetTheme.textMuted),
        ),
      ),
    );
  }
}
