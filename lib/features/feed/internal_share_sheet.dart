import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/features/chat/chat_list_screen.dart';

class InternalShareSheet extends ConsumerWidget {
  final int postId;
  final String postContent;

  const InternalShareSheet({
    super.key, 
    required this.postId,
    required this.postContent
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListProvider);
    final currentUser = ref.watch(userProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 16, bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text('Send to Friends', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.search, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: chatsAsync.when(
              data: (chats) {
                if (chats.isEmpty) {
                  return const Center(child: Text("No recent chats found."));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: chat['avatar'] != null ? NetworkImage(chat['avatar']) : null,
                        child: chat['avatar'] == null ? Text(chat['name'][0]) : null,
                      ),
                      title: Text(chat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final message = "Shared a post: shelpet://post/${postId}";
                          await ApiService.sendMessage(currentUser!.id, int.parse(chat['id'].toString()), message);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Sent to ${chat['name']}!"))
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShelPetTheme.primaryAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Send', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }
}
