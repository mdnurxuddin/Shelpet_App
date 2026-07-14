import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/features/feed/post_provider.dart';
import 'package:shelpet/features/feed/create_post_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class RescueScreen extends ConsumerWidget {
  const RescueScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final currentUser = ref.watch(userProvider);
    final bool isVerified = currentUser?.status == 'verified';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emergency Rescue Ops',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: ShelPetTheme.textPrimary),
        ),
      ),
      body: postsAsync.when(
        data: (posts) {
          final rescuePosts = posts.where((p) => p.type == 'rescue' && p.status != 'done').toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(postsProvider.future),
            color: ShelPetTheme.primaryAccent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildUrgentBanner(context, isVerified),
                const SizedBox(height: 24),
                Text(
                  'Active Reports',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                ...rescuePosts.map((post) => _buildRescueCard(context, ref, post, currentUser?.id, isVerified)).toList(),
                if (rescuePosts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'No active rescue reports',
                        style: TextStyle(color: ShelPetTheme.textMuted),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildUrgentBanner(BuildContext context, bool isVerified) {
    return GestureDetector(
      onTap: () {
        if (isVerified) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreatePostDialog(defaultType: 'rescue'),
          );
        } else {
          _showVerifyAlert(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFD32F2F)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: const Row(
          children: [
            Icon(FontAwesomeIcons.circleExclamation, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap here to quickly report an animal in danger.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRescueCard(BuildContext context, WidgetRef ref, Post post, int? currentUserId, bool isUserVerified) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.image != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(
                post.image!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[100],
                  child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (post.status == 'done')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle, color: Colors.green, size: 14),
                            SizedBox(width: 4),
                            Text(
                              "Rescued",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      )
                    else if (post.status == 'urgent')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Urgent",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Active Case",
                          style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    Text(
                      post.createdAt,
                      style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: ShelPetTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: ShelPetTheme.secondaryAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      post.location ?? 'Unknown Location',
                      style: const TextStyle(color: ShelPetTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (currentUserId == post.userId)
                  if (post.status == 'done')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.done_all, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Animal Safely Rescued! 🎉",
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Marking as rescued...")),
                          );
                          final res = await ApiService.updatePostStatus(post.id, 'done');
                          if (res['status'] == true) {
                            ref.invalidate(postsProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Status updated! Animal has been rescued. 🎉")),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: ${res['message']}")),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                        label: const Text('Mark as Rescued', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!isUserVerified) {
                           _showVerifyAlert(context);
                           return;
                        }
                        context.push('/user-profile/${post.userId}');
                      },
                      icon: const Icon(Icons.call, size: 16, color: Colors.white),
                      label: const Text('Contact Reporter', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUserVerified ? ShelPetTheme.primaryAccent : Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
