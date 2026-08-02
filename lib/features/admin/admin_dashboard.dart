import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/features/feed/post_provider.dart';
import 'package:shelpet/features/store/store_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

final pendingUsersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ApiService.getPendingUsers();
});

final allUsersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ApiService.getAllUsers();
});

final adminAllProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final list = await ApiService.getProducts('All');
  return list.map((e) => Product.fromJson(e)).toList();
});

final adminAllOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ApiService.getAllOrdersAdmin();
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
      body: _buildSelectedTab(adminUser?.id),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: ShelPetTheme.primaryAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_rounded),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_rounded),
            label: 'Store',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Users',
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTab(int? adminUserId) {
    switch (_currentIndex) {
      case 0:
        return _buildNidApprovalsTab(adminUserId);
      case 1:
        return _buildStoreManagementTab(adminUserId);
      case 2:
        return _buildStoreOrdersTab(adminUserId);
      case 3:
        return _buildPostModerationTab(adminUserId);
      case 4:
        return _buildManageUsersTab(adminUserId);
      default:
        return _buildNidApprovalsTab(adminUserId);
    }
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

  Widget _buildStoreManagementTab(int? adminUserId) {
    final productsAsync = ref.watch(adminAllProductsProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Store Inventory', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  productsAsync.when(
                    data: (products) => Text('${products.length} Products Total', style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 12)),
                    loading: () => const Text('Loading products...', style: TextStyle(color: ShelPetTheme.textMuted, fontSize: 12)),
                    error: (_, __) => const Text('Store error', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CreateProductDialog(),
                  ).then((_) => ref.invalidate(adminAllProductsProvider));
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShelPetTheme.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(adminAllProductsProvider.future),
            color: ShelPetTheme.primaryAccent,
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('No products in store', style: TextStyle(color: ShelPetTheme.textMuted)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: product.image != null && product.image!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: product.image!,
                                    width: 65,
                                    height: 65,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, e, s) => Container(width: 65, height: 65, color: Colors.grey[100], child: const Icon(Icons.shopping_bag)),
                                  )
                                : Container(width: 65, height: 65, color: Colors.grey[100], child: const Icon(Icons.shopping_bag)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('৳${product.price.toStringAsFixed(0)} • ${product.category.toUpperCase()}', style: const TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (product.stock > 5 ? Colors.green : product.stock > 0 ? Colors.orange : Colors.red).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Stock: ${product.stock}',
                                        style: TextStyle(
                                          color: product.stock > 5 ? Colors.green : product.stock > 0 ? Colors.orange.shade800 : Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: ShelPetTheme.primaryAccent),
                                tooltip: 'Update Stock',
                                onPressed: () => _showUpdateStockDialog(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                tooltip: 'Delete Product',
                                onPressed: () => _confirmDeleteProduct(product),
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
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreOrdersTab(int? adminUserId) {
    final ordersAsync = ref.watch(adminAllOrdersProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adminAllOrdersProvider.future),
      color: ShelPetTheme.primaryAccent,
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('No orders placed yet', style: TextStyle(color: ShelPetTheme.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final int orderId = int.parse(order['id'].toString());
              final String status = (order['status'] ?? 'pending').toString().toLowerCase();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order #${order['id']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: order['product_image'] != null && order['product_image'].toString().isNotEmpty
                              ? CachedNetworkImage(imageUrl: order['product_image'], width: 50, height: 50, fit: BoxFit.cover)
                              : Container(width: 50, height: 50, color: Colors.grey[100], child: const Icon(Icons.shopping_bag)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order['product_name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Total: ৳${order['total_price']}', style: const TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Buyer: ${order['buyer_name']} (${order['phone_number']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('Address: ${order['shipping_address']}', style: const TextStyle(fontSize: 12, color: ShelPetTheme.textMuted)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Change Status: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: ['pending', 'accepted', 'shipped', 'delivered', 'cancelled'].contains(status) ? status : 'pending',
                          items: ['pending', 'accepted', 'shipped', 'delivered', 'cancelled'].map((st) {
                            return DropdownMenuItem(
                              value: st,
                              child: Text(st.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(st))),
                            );
                          }).toList(),
                          onChanged: (newStatus) async {
                            if (newStatus != null) {
                              final res = await ApiService.updateOrderStatus(orderId, newStatus);
                              if (res['status'] == true) {
                                ref.invalidate(adminAllOrdersProvider);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order #$orderId status updated to $newStatus')));
                              }
                            }
                          },
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
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  void _showUpdateStockDialog(Product product) {
    final stockController = TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock: ${product.name}'),
        content: TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stock Quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(stockController.text.trim());
              if (newStock != null) {
                final res = await ApiService.updateProductStock(product.id, newStock);
                if (res['status'] == true) {
                  Navigator.pop(context);
                  ref.invalidate(adminAllProductsProvider);
                  ref.invalidate(productsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock updated successfully!')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${product.name}?'),
        content: const Text('Are you sure you want to delete this product from the store?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.deleteProduct(product.id);
      if (res['status'] == true) {
        ref.invalidate(adminAllProductsProvider);
        ref.invalidate(productsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted from store!')));
      }
    }
  }
}
