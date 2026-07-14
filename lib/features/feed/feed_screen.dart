import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/features/feed/post_provider.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/features/feed/create_post_dialog.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:shelpet/core/favorites_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shelpet/features/feed/comments_bottom_sheet.dart';
import 'package:shelpet/features/feed/internal_share_sheet.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/notification_provider.dart';


class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  void _showVerifyAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please Verify Your Account to perform this action.'),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VERIFY',
          textColor: Colors.white,
          onPressed: () => context.push('/verify-account'),
        ),
      ),
    );
  }

  void _showCreatePost(BuildContext context, bool isVerified) {
    if (!isVerified) {
      _showVerifyAlert(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final user = ref.watch(userProvider);
    final String verificationStatus = user?.status ?? 'pending';
    final bool isVerified = verificationStatus == 'verified';
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: Text(
          'ShelPet Community',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: ShelPetTheme.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 18),
          ),
          IconButton(
            onPressed: () {
               if (!isVerified) {
                 _showVerifyAlert(context);
               } else {
                 context.push('/chats');
               }
            },
            icon: const Icon(FontAwesomeIcons.solidCommentDots, size: 20),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  ref.read(notificationProvider.notifier).updateCount(0);
                  context.push('/notifications');
                },
                icon: const Icon(FontAwesomeIcons.bell, size: 20),
              ),
              Consumer(builder: (context, ref, child) {
                final unreadCount = ref.watch(notificationProvider).unreadCount;
                if (unreadCount == 0) return const SizedBox.shrink();
                return Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (!isVerified) _buildPendingBanner(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(userProvider.notifier).refreshUser();
                await ref.refresh(postsProvider.future);
              },
              color: ShelPetTheme.primaryAccent,
              child: postsAsync.when(
                data: (posts) => posts.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: _buildPremiumPostCard(context, posts[index], isVerified, favorites, ref),
                        );
                      },
                    ),
                loading: () => _buildShimmerLoading(),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePost(context, isVerified),
        backgroundColor: isVerified ? ShelPetTheme.primaryAccent : Colors.grey,
        label: Text(isVerified ? 'Post' : 'Verify to Post', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPendingBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/verify-account'),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: Colors.orange.shade700, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Verification Required: Please verify your account with NID to unlock posting and interactions.',
                style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.orange.shade300, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.paw, size: 80, color: ShelPetTheme.textMuted.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text('No stories yet!', style: GoogleFonts.outfit(fontSize: 18, color: ShelPetTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          height: 350,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  Widget _buildPremiumPostCard(BuildContext context, Post post, bool isVerified, Set<int> favorites, WidgetRef ref) {
    final isFav = favorites.contains(post.id);
    final user = ref.watch(userProvider);
    final bool canDelete = (user != null) && (user.id == post.userId || user.role == 'admin');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/user-profile/${post.userId}'),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ShelPetTheme.secondaryAccent.withOpacity(0.2), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: ShelPetTheme.secondaryAccent.withOpacity(0.05),
                      backgroundImage: post.userAvatar != null && post.userAvatar!.isNotEmpty
                          ? NetworkImage(post.userAvatar!)
                          : null,
                      child: post.userAvatar == null || post.userAvatar!.isEmpty
                          ? Text(post.userName[0], style: const TextStyle(color: ShelPetTheme.secondaryAccent, fontWeight: FontWeight.bold, fontSize: 14))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.userName,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: ShelPetTheme.textPrimary),
                            ),
                          ),
                          if (post.userId == 1) ...[ // Assuming ID 1 is Admin
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: ShelPetTheme.secondaryAccent, size: 14),
                          ],
                        ],
                      ),
                      Text(post.createdAt, style: TextStyle(color: ShelPetTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
                      if (post.type == 'fostering' && post.status != 'done') ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.2)),
                          ),
                          child: Text(
                            "৳${post.price.toInt()} / day",
                            style: const TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildTypeBadge(post.type, post.status),
                if (canDelete) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: ShelPetTheme.textMuted, size: 20),
                    onPressed: () => _showPostOptions(context, ref, post, user!),
                  ),
                ],
              ],
            ),
          ),
          
          // Content Section (Text before image for modern look)
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                post.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: ShelPetTheme.textPrimary.withOpacity(0.9),
                ),
              ),
            ),

          // Image Section
          if (post.image != null && post.image!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  post.image!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
            
          // Location and Interaction Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.location != null && post.location!.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: ShelPetTheme.secondaryAccent),
                      const SizedBox(width: 4),
                      Text(
                        post.location!,
                        style: GoogleFonts.outfit(color: ShelPetTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    _buildCompactAction(
                      post.hasLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                      post.likesCount.toString(),
                      post.hasLiked ? Colors.redAccent : ShelPetTheme.textSecondary,
                      () async {
                        if (!isVerified) { _showVerifyAlert(context); return; }
                        if (user != null) {
                          await ApiService.toggleReaction(user.id, post.id);
                          ref.invalidate(postsProvider);
                        }
                      }
                    ),
                    const SizedBox(width: 20),
                    _buildCompactAction(
                      FontAwesomeIcons.comment,
                      post.commentsCount.toString(),
                      ShelPetTheme.textSecondary,
                      () {
                        if (!isVerified) { _showVerifyAlert(context); return; }
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => CommentsBottomSheet(postId: post.id),
                        );
                      }
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => InternalShareSheet(postId: post.id, postContent: post.content),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: ShelPetTheme.secondaryAccent.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(FontAwesomeIcons.shareNodes, size: 14, color: ShelPetTheme.secondaryAccent),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(post.id),
                      child: Icon(
                        isFav ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                        color: isFav ? ShelPetTheme.primaryAccent : ShelPetTheme.textMuted.withOpacity(0.4),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAction(IconData icon, String count, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          if (count.isNotEmpty && count != "0") ...[
            const SizedBox(width: 6),
            Text(
              count,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: ShelPetTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernInteraction(IconData icon, String count, Color color, VoidCallback onTap, bool isEnabled) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.4,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (count.isNotEmpty && count != "0") ...[
              const SizedBox(width: 10),
              Text(
                count,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: ShelPetTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context, WidgetRef ref, Post post, UserProfile user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Delete Post', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Post?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Delete', style: TextStyle(color: Colors.white))),
                  ],
                ),
              );
              if (confirm == true) {
                final response = await ApiService.deletePost(user.id, post.id);
                if (response['status'] == true) {
                  ref.invalidate(postsProvider);
                }
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type, String? status) {
    Color color = ShelPetTheme.secondaryAccent;
    IconData icon = Icons.feed_outlined;
    String label = type.toUpperCase();

    if (status == 'done') {
      color = Colors.green;
      icon = Icons.check_circle_rounded;
      if (type == 'adoption') {
        label = "ADOPTED 🎉";
      } else if (type == 'fostering') {
        label = "FOSTERED 🎉";
      } else {
        label = "RESCUED 🎉";
      }
    } else {
      if (type == 'rescue') {
        color = Colors.redAccent;
        icon = Icons.emergency_share;
      }
      if (type == 'adoption') {
        color = Colors.green;
        icon = Icons.pets;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
