import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/phone_verification_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerWidget {
  final int? targetUserId;
  const ProfileScreen({super.key, this.targetUserId});

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

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref, UserProfile user) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 16),
              Text("Uploading display picture..."),
            ],
          ),
          duration: Duration(days: 1),
        ),
      );

      final imageUrl = await ApiService.uploadImage(pickedFile.path);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload image")));
        return;
      }

      final response = await ApiService.updateAvatar(user.id, imageUrl);

      if (response['status'] == true) {
        final updatedUser = UserProfile(
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          avatar: imageUrl,
          category: user.category,
          status: user.status,
          rating: user.rating,
          role: user.role,
          address: user.address,
        );
        await ref.read(userProvider.notifier).setUser(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated successfully!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider);
    final isSelf = targetUserId == null || targetUserId == currentUser?.id;

    if (isSelf) {
      if (currentUser == null) {
        return const Scaffold(
          body: Center(child: Text('Please login to view profile')),
        );
      }
      return _buildProfileContent(context, ref, currentUser, true, currentUser);
    } else {
      final otherUserAsync = ref.watch(otherUserProfileProvider(targetUserId!));
      return otherUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Scaffold(
              body: Center(child: Text('User profile not found')),
            );
          }
          return _buildProfileContent(context, ref, user, false, currentUser);
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Error loading profile: $err')),
        ),
      );
    }
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, UserProfile user, bool isSelf, UserProfile? currentUser) {
    final statsAsync = ref.watch(userStatsProvider(user.id));
    final reviewsAsync = isSelf ? null : ref.watch(userReviewsProvider(user.id));
    final bool isVerified = currentUser?.status == 'verified';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ShelPetTheme.secondaryAccent, Colors.white],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    GestureDetector(
                      onTap: isSelf ? () => _changeAvatar(context, ref, user) : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: ShelPetTheme.primaryAccent.withOpacity(0.1),
                              backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                                  ? NetworkImage(user.avatar!)
                                  : null,
                              child: user.avatar == null || user.avatar!.isEmpty
                                  ? Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: ShelPetTheme.primaryAccent),
                                    )
                                  : null,
                            ),
                          ),
                          if (isSelf)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: ShelPetTheme.primaryAccent, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary),
                        ),
                        if (user.status == 'verified') ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: ShelPetTheme.primaryAccent, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(user.category, style: const TextStyle(color: ShelPetTheme.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(' ${user.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (user.hasPhone) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _showContactOptions(context, user.phone!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: ShelPetTheme.primaryAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ShelPetTheme.primaryAccent.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, color: ShelPetTheme.primaryAccent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                user.phone!,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: ShelPetTheme.primaryAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded, color: ShelPetTheme.primaryAccent, size: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (user.address != null && user.address!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: ShelPetTheme.primaryAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            user.address!,
                            style: GoogleFonts.inter(fontSize: 13, color: ShelPetTheme.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                statsAsync.when(
                  data: (stats) {
                    final int posts = stats?['posts'] ?? 0;
                    final int adoptions = stats?['adoptions'] ?? 0;
                    final int rescues = stats?['rescues'] ?? 0;
                    final int reviews = stats?['reviews'] ?? 0;
                    return _buildStatRow(context, posts, adoptions, rescues, reviews, user);
                  },
                  loading: () => _buildStatRow(context, 0, 0, 0, 0, user),
                  error: (_, __) => _buildStatRow(context, 0, 0, 0, 0, user),
                ),
                const SizedBox(height: 30),
                if (isSelf) ...[
                  Text('Account Settings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildOptionTile(
                    Icons.shield_outlined, 
                    'Rescue & Adoption History', 
                    'Your track record of saved & adopted pets',
                    color: Colors.teal,
                    onTap: () => _showUserHistorySheet(context, ref, user),
                  ),
                  _buildOptionTile(
                    user.hasPhone ? Icons.phone_android_rounded : Icons.phone_locked_rounded,
                    user.hasPhone ? 'Phone Number' : 'Add Phone Number (Required)',
                    user.hasPhone ? user.phone! : 'Tap to add phone number to enable posting & buying',
                    color: user.hasPhone ? ShelPetTheme.primaryAccent : Colors.orange.shade800,
                    onTap: () => PhoneVerificationHelper.showPhoneRequiredDialog(context, ref),
                  ),
                  _buildOptionTile(
                    Icons.history, 
                    'My Activity', 
                    'Track your posts & adoptions',
                    onTap: () => context.push('/my-activity'),
                  ),
                  _buildOptionTile(
                    Icons.shopping_bag_outlined, 
                    'My Store Orders', 
                    'Track your store orders & delivery status',
                    color: ShelPetTheme.primaryAccent,
                    onTap: () => context.push('/my-orders'),
                  ),
                  _buildOptionTile(
                    Icons.favorite_outline, 
                    'My Favorites', 
                    'Pets you loved',
                    onTap: () => context.push('/my-favorites'),
                  ),
                  _buildOptionTile(
                    Icons.badge_outlined, 
                    'Verification Status', 
                    user.status.toUpperCase(), 
                    color: user.status == 'verified' ? Colors.green : Colors.orange,
                    onTap: user.status != 'verified' ? () => context.push('/verify-account') : null,
                  ),
                  _buildOptionTile(
                    Icons.settings_outlined, 
                    'Settings', 
                    'Theme, notifications & more',
                    onTap: () => context.push('/settings'),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(userProvider.notifier).clear();
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  if (user.hasPhone) ...[
                    _buildOptionTile(
                      Icons.phone_android_rounded,
                      'Contact Phone',
                      user.phone!,
                      color: Colors.green,
                      onTap: () => _showContactOptions(context, user.phone!),
                    ),
                  ],
                  if (currentUser != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (!isVerified) {
                            _showVerifyAlert(context);
                          } else {
                            _showReviewDialog(context, ref, user.id, currentUser.id);
                          }
                        },
                        icon: const Icon(Icons.star_outline),
                        label: const Text("Write a Review"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isVerified ? Colors.amber.shade700 : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (user.hasPhone) ...[
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: () => _showContactOptions(context, user.phone!),
                              icon: const Icon(Icons.call, color: Colors.white),
                              label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (!isVerified) {
                                _showVerifyAlert(context);
                              } else {
                                context.push('/chat/${user.id}/${user.name}');
                              }
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Message User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isVerified ? ShelPetTheme.primaryAccent : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildOptionTile(
                    Icons.shield_outlined,
                    'Trust & Rescue Record',
                    'See previous rescued & adopted animals',
                    color: Colors.teal,
                    onTap: () => _showUserHistorySheet(context, ref, user),
                  ),
                  const SizedBox(height: 20),
                  Text('User Reviews', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (reviewsAsync != null) reviewsAsync.when(
                    data: (reviews) => reviews.isEmpty 
                      ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No reviews yet')))
                      : Column(children: reviews.map((r) => _buildReviewCard(r)).toList()),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error loading reviews: $err'),
                  ),
                ],
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, int posts, int adoptions, int rescues, int reviews, UserProfile user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Posts', posts.toString()),
          _buildStat('Adoptions', adoptions.toString()),
          _buildStat('Rescues', rescues.toString()),
          _buildStat(
            'Reviews', 
            reviews.toString(), 
            onTap: () => context.push('/user-reviews/${user.id}?name=${Uri.encodeComponent(user.name)}'),
          ),
        ],
      ),
    );
  }

  void _showUserHistorySheet(BuildContext context, WidgetRef ref, UserProfile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final historyAsync = ref.watch(userHistoryProvider(user.id));
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Colors.teal, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.name}\'s Track Record',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Verified animal rescue & adoption history',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: historyAsync.when(
                      data: (history) {
                        if (history.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.pets_rounded, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No completed rescues or adoptions yet',
                                  style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            final type = item['type'] ?? 'adoption';
                            final title = item['content'] ?? 'Animal Post';
                            final image = item['image'];
                            final location = item['location'] ?? 'Unknown Location';
                            final date = item['created_at'] != null ? item['created_at'].toString().split(' ')[0] : '';
                            
                            Color badgeColor = Colors.blue;
                            String badgeText = 'ADOPTED';
                            if (type == 'rescue') {
                              badgeColor = Colors.green;
                              badgeText = 'RESCUED & SAFE';
                            } else if (type == 'fostering') {
                              badgeColor = Colors.amber.shade800;
                              badgeText = 'FOSTERED';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ShelPetTheme.lightBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: image != null && image.toString().isNotEmpty
                                        ? Image.network(image, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholderImage())
                                        : _buildPlaceholderImage(),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                badgeText,
                                                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                location,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error loading history: $err')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.teal.shade50,
      child: const Icon(Icons.pets, color: Colors.teal, size: 30),
    );
  }

  Widget _buildStat(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: ShelPetTheme.primaryAccent)),
          Text(label, style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String subtitle, {Color? color, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: (color ?? ShelPetTheme.primaryAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color ?? ShelPetTheme.primaryAccent, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: ShelPetTheme.textMuted)),
        trailing: const Icon(Icons.chevron_right, color: ShelPetTheme.textMuted, size: 18),
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
     return Container(); // Placeholder for now
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref, int targetId, int reviewerId) {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Rate this User', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => selectedRating = index + 1.0),
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  filled: true,
                  fillColor: ShelPetTheme.lightBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final res = await ApiService.submitReview(
                  reviewerId: reviewerId,
                  targetId: targetId,
                  rating: selectedRating,
                  comment: commentController.text,
                );
                if (res['status'] == true) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for your review!")));
                  await ref.read(userProvider.notifier).refreshUser(); // Refresh rating
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactOptions(BuildContext context, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.phone, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact Number', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: ShelPetTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text(phone, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: ShelPetTheme.primaryAccent)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Phone: $phone')));
                        }
                      }
                    },
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: const Text('Call Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Clipboard.setData(ClipboardData(text: phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number copied to clipboard!'), backgroundColor: Colors.green),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
