import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/features/feed/post_provider.dart';

final pendingUsersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ApiService.getPendingUsers();
});

final allUsersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ApiService.getAllUsers();
});

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final adminUser = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: Text(
          'ShelPet Admin',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: ShelPetTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Log Out',
            onPressed: () async {
              await ref.read(userProvider.notifier).clear();
            },
          ),
        ],
      ),
      body: _currentIndex == 0 
          ? _buildNidApprovalsTab(adminUser?.id) 
          : _currentIndex == 1 
              ? _buildPostModerationTab(adminUser?.id)
              : _buildManageUsersTab(adminUser?.id),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: ShelPetTheme.primaryAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_rounded),
            label: 'NID Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: 'Post Moderation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Manage Users',
          ),
        ],
      ),
    );
  }

  Widget _buildNidApprovalsTab(int? adminUserId) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);

    return pendingUsersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  'No pending NID requests!',
                  style: GoogleFonts.outfit(fontSize: 18, color: ShelPetTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final int userId = int.parse(user['id'].toString());

            return FadeInUp(
              delay: Duration(milliseconds: index * 50),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: ShelPetTheme.primaryAccent.withOpacity(0.1),
                          backgroundImage: user['avatar'] != null && user['avatar'].toString().isNotEmpty
                              ? NetworkImage(user['avatar'])
                              : null,
                          child: user['avatar'] == null || user['avatar'].toString().isEmpty
                              ? Text(
                                  user['name'].toString().isNotEmpty ? user['name'][0].toUpperCase() : 'U',
                                  style: const TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? 'No Name',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary),
                              ),
                              Text(
                                user['email'] ?? 'No Email',
                                style: const TextStyle(fontSize: 13, color: ShelPetTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'NID Number:',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: ShelPetTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['nid_number'] ?? 'N/A',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary),
                    ),
                    if (user['nid_front_image'] != null && user['nid_front_image'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                           showDialog(
                             context: context,
                             builder: (context) => Dialog(
                               backgroundColor: Colors.transparent,
                               child: InteractiveViewer(
                                 child: Image.network(user['nid_front_image']),
                               ),
                             ),
                           );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            user['nid_front_image'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 100, 
                              color: Colors.grey[100], 
                              child: const Icon(Icons.broken_image_outlined, color: Colors.grey)
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _updateUserStatus(userId, 'rejected'),
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _updateUserStatus(userId, 'verified'),
                          icon: const Icon(Icons.check, color: Colors.white, size: 16),
                          label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildPostModerationTab(int? adminUserId) {
    final postsAsync = ref.watch(postsProvider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No posts to moderate.',
              style: GoogleFonts.outfit(fontSize: 16, color: ShelPetTheme.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];

            return FadeInUp(
              delay: Duration(milliseconds: index * 50),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          post.userName,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: ShelPetTheme.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ShelPetTheme.primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            post.type.toUpperCase(),
                            style: const TextStyle(color: ShelPetTheme.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ShelPetTheme.textSecondary, fontSize: 14),
                    ),
                    if (post.image != null && post.image!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          post.image!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          post.createdAt,
                          style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 11),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _confirmDeletePost(adminUserId, post.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildManageUsersTab(int? adminUserId) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users registered yet.',
              style: GoogleFonts.outfit(fontSize: 16, color: ShelPetTheme.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final int userId = int.parse(user['id'].toString());
            final String role = user['role'] ?? 'user';
            final bool isAdminUser = role == 'admin';

            return FadeInUp(
              delay: Duration(milliseconds: index * 50),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isAdminUser ? Colors.orange.withOpacity(0.1) : ShelPetTheme.primaryAccent.withOpacity(0.1),
                      child: Icon(
                        isAdminUser ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                        color: isAdminUser ? Colors.orange : ShelPetTheme.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user['name'] ?? 'No Name',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary),
                              ),
                              if (isAdminUser) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('ADMIN', style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            user['email'] ?? 'No Email',
                            style: const TextStyle(fontSize: 13, color: ShelPetTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${user['user_category'] ?? 'Adoptor'}',
                            style: TextStyle(fontSize: 12, color: ShelPetTheme.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (!isAdminUser && userId != adminUserId)
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                        tooltip: 'Delete User Account',
                        onPressed: () => _confirmDeleteUser(adminUserId, userId, user['name'] ?? 'this user'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Future<void> _updateUserStatus(int userId, String status) async {
    final response = await ApiService.updateUserVerificationStatus(userId, status);
    if (response['status'] == true) {
      ref.invalidate(pendingUsersProvider);
      ref.invalidate(allUsersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User NID status updated to $status!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to update user status.')),
      );
    }
  }

  Future<void> _confirmDeletePost(int? adminUserId, int postId) async {
    if (adminUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await ApiService.deletePost(adminUserId, postId);
      if (response['status'] == true) {
        ref.invalidate(postsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to delete post.')),
        );
      }
    }
  }

  Future<void> _confirmDeleteUser(int? adminUserId, int targetUserId, String targetUserName) async {
    if (adminUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $targetUserName?'),
        content: Text('Are you sure you want to permanently delete $targetUserName\'s account? This will cascade delete all of their posts, reviews, products, and chat history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await ApiService.deleteUser(adminUserId, targetUserId);
      if (response['status'] == true) {
        ref.invalidate(allUsersProvider);
        ref.invalidate(postsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$targetUserName\'s account has been successfully deleted.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to delete user account.')),
        );
      }
    }
  }
}
