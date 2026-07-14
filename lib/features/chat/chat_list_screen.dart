import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final chatListProvider = FutureProvider<List<dynamic>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];
  return ApiService.getChats(user.id);
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListProvider);
    final user = ref.watch(userProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view chats')),
      );
    }

    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: ShelPetTheme.textPrimary),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(chatListProvider.future),
        color: ShelPetTheme.primaryAccent,
        child: chatsAsync.when(
          data: (chats) {
            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.solidCommentDots, size: 80, color: ShelPetTheme.textMuted.withOpacity(0.15)),
                    const SizedBox(height: 16),
                    Text(
                      'No conversations yet',
                      style: TextStyle(color: ShelPetTheme.textMuted, fontSize: 15),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final int otherId = int.parse(chat['id'].toString());
                final String otherName = chat['name'] ?? 'User';
                final String? otherAvatar = chat['avatar'];
                final String lastMsg = chat['last_message'] ?? '';
                final String lastTime = chat['last_message_time'] ?? '';
                final int unreadCount = int.parse((chat['unread_count'] ?? 0).toString());

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: unreadCount > 0 ? ShelPetTheme.primaryAccent.withOpacity(0.1) : Colors.black.withOpacity(0.04)),
                  ),
                  child: ListTile(
                    onTap: () async {
                      // Mark as read
                      await http.post(
                        Uri.parse("${ApiService.baseUrl}/chat/mark_chat_read.php"),
                        body: jsonEncode({"user_id": user.id, "other_id": otherId})
                      );
                      ref.invalidate(chatListProvider);
                      context.push('/chat/$otherId/$otherName');
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: ShelPetTheme.primaryAccent.withOpacity(0.1),
                          backgroundImage: otherAvatar != null ? NetworkImage(otherAvatar) : null,
                          child: otherAvatar == null
                              ? Text(otherName[0].toUpperCase(), style: const TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: 14,
                              width: 14,
                              decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          otherName,
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600, 
                            fontSize: 16, 
                            color: ShelPetTheme.textPrimary
                          ),
                        ),
                        Text(
                          _formatTime(lastTime),
                          style: TextStyle(
                            color: unreadCount > 0 ? ShelPetTheme.primaryAccent : ShelPetTheme.textMuted, 
                            fontSize: 11,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unreadCount > 0 ? ShelPetTheme.textPrimary : ShelPetTheme.textMuted, 
                                fontSize: 13,
                                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: ShelPetTheme.primaryAccent, shape: BoxShape.circle),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(timeString);
      final now = DateTime.now();
      if (now.day == dateTime.day && now.month == dateTime.month && now.year == dateTime.year) {
        return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      }
      return "${dateTime.day}/${dateTime.month}";
    } catch (e) {
      return '';
    }
  }
}
