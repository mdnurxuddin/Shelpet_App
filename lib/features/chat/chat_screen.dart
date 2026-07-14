import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/features/feed/post_provider.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  Timer? _pollingTimer;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Start periodic polling every 3 seconds to fetch new messages
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    final list = await ApiService.getMessages(user.id, widget.receiverId);
    if (!mounted) return;

    setState(() {
      _messages = list;
    });

    if (_isFirstLoad && list.isNotEmpty) {
      _isFirstLoad = false;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userProvider);
    if (user == null) return;

    _messageController.clear();

    // Optimistically insert message to UI for instant feedback
    setState(() {
      _messages.add({
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "sender_id": user.id,
        "receiver_id": widget.receiverId,
        "message": text,
        "created_at": DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    final response = await ApiService.sendMessage(user.id, widget.receiverId, text);
    if (response['status'] == true) {
      _fetchMessages();
    }
  }

  void _showDealDoneDialog() {
    final user = ref.read(userProvider);
    final postsAsync = ref.read(postsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('Complete a Deal', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Select the listing you want to mark as completed with ${widget.receiverName}.', style: TextStyle(color: ShelPetTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: postsAsync.when(
                data: (posts) {
                  final myActiveDeals = posts.where((p) => 
                    p.userId == user?.id && 
                    (p.type == 'adoption' || p.type == 'fostering') && 
                    p.status != 'done'
                  ).toList();

                  if (myActiveDeals.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text("No active adoption or fostering posts.", style: TextStyle(color: ShelPetTheme.textMuted))),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: myActiveDeals.length,
                    itemBuilder: (context, index) {
                      final post = myActiveDeals[index];
                      final bool isAdoption = post.type == 'adoption';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ShelPetTheme.lightBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black.withOpacity(0.03)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: (isAdoption ? Colors.green : Colors.orange).withOpacity(0.1), shape: BoxShape.circle),
                                  child: Icon(isAdoption ? Icons.pets : Icons.volunteer_activism, color: isAdoption ? Colors.green : Colors.orange, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(isAdoption ? 'Pet Adoption' : 'Paid Fostering', style: TextStyle(color: ShelPetTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel', style: TextStyle(color: ShelPetTheme.textMuted, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final res = await ApiService.updatePostStatus(post.id, 'done');
                                      if (res['status'] == true) {
                                        ref.invalidate(postsProvider);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Deal completed successfully! 🎉"), backgroundColor: Colors.green),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isAdoption ? Colors.green : Colors.orange.shade700,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: ShelPetTheme.primaryAccent.withOpacity(0.1),
              child: Text(
                widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : 'U',
                style: const TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text('Active Now', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showDealDoneDialog,
            icon: const Icon(Icons.handshake_rounded, color: ShelPetTheme.primaryAccent),
            tooltip: 'Mark Deal Done',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Say hi!',
                      style: TextStyle(color: ShelPetTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final bool isMe = msg['sender_id'].toString() == user?.id.toString();
                      return _buildMessage(msg['message'] ?? '', isMe);
                    },
                  ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isMe) {
    final bool isPostShare = text.contains('shelpet://post/');
    int? sharedPostId;
    if (isPostShare) {
      final match = RegExp(r'shelpet://post/(\d+)').firstMatch(text);
      if (match != null) {
        sharedPostId = int.parse(match.group(1)!);
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: isPostShare && sharedPostId != null 
          ? () => context.push('/post/$sharedPostId')
          : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe 
              ? (isPostShare ? Colors.blue.shade700 : ShelPetTheme.primaryAccent) 
              : (isPostShare ? Colors.blue.shade50 : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 20),
            ),
            border: isMe ? null : Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: isPostShare 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.share_rounded, size: 16, color: isMe ? Colors.white70 : Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Shared a Post',
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click to view this pet story',
                    style: TextStyle(
                      color: isMe ? Colors.white.withOpacity(0.9) : Colors.black87,
                      fontSize: 14,
                      decoration: TextDecoration.underline
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: TextStyle(color: isMe ? Colors.white : ShelPetTheme.textPrimary, fontSize: 14),
              ),
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.04))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: ShelPetTheme.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: ShelPetTheme.primaryAccent,
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
