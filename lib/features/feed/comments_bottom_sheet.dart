import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/features/feed/post_provider.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final int postId;
  const CommentsBottomSheet({super.key, required this.postId});

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  List<dynamic> _allComments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  // Reply tracking
  int? _replyToId;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getComments(widget.postId);
    if (mounted) {
      setState(() {
        _allComments = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final response = await ApiService.addComment(
      user.id, 
      widget.postId, 
      text, 
      parentId: _replyToId
    );
    
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (response['status'] == true) {
          _commentController.clear();
          _replyToId = null;
          _replyToName = null;
          _loadComments();
          ref.invalidate(postsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to post comment')),
          );
        }
      });
    }
  }

  void _startReply(int commentId, String userName) {
    setState(() {
      _replyToId = commentId;
      _replyToName = userName;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToId = null;
      _replyToName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Separate parents and children
    final parentComments = _allComments.where((c) => c['parent_id'] == null).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(top: 16, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments (${_allComments.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ShelPetTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : parentComments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet. Start the conversation!',
                          style: TextStyle(color: ShelPetTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: parentComments.length,
                        itemBuilder: (context, index) {
                          final parent = parentComments[index];
                          final int parentId = int.parse(parent['id'].toString());
                          final replies = _allComments.where((c) => c['parent_id'] != null && int.parse(c['parent_id'].toString()) == parentId).toList();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCommentTile(parent, isReply: false),
                              if (replies.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 44, top: 8),
                                  child: Column(
                                    children: replies.map((r) => _buildCommentTile(r, isReply: true)).toList(),
                                  ),
                                ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
          ),
          const Divider(height: 1),
          // Reply Indicator
          if (_replyToId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: ShelPetTheme.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to $_replyToName',
                      style: const TextStyle(fontSize: 12, color: ShelPetTheme.textSecondary),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: ShelPetTheme.textMuted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: ShelPetTheme.primaryAccent,
                          ),
                          onPressed: _submitComment,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(dynamic c, {required bool isReply}) {
    final String name = c['user_name'] ?? 'User';
    final String? avatar = c['user_avatar'];
    final String content = c['content'] ?? '';
    final int commentId = int.parse(c['id'].toString());

    return Padding(
      padding: EdgeInsets.only(bottom: isReply ? 12 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: ShelPetTheme.primaryAccent.withOpacity(0.1),
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: ShelPetTheme.primaryAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: isReply ? 10 : 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isReply ? Colors.grey.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ShelPetTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isReply)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: GestureDetector(
                      onTap: () => _startReply(commentId, name),
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          color: ShelPetTheme.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
