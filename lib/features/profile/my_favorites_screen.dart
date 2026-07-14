import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/favorites_provider.dart';
import 'package:shelpet/features/feed/post_provider.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:go_router/go_router.dart';

class MyFavoritesScreen extends ConsumerWidget {
  const MyFavoritesScreen({super.key});

  void _showPostDetails(BuildContext context, Post post, int? currentUserId) {
    final isFostering = post.type == 'fostering';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.image != null && post.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    post.image!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 220,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isFostering ? 'Paid Fostering Service' : 'Pet for Adoption',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFostering ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isFostering ? '${post.price.toInt()} BDT / Day' : 'Available',
                      style: TextStyle(
                        color: isFostering ? Colors.orange.shade800 : Colors.green, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 11
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: ShelPetTheme.primaryAccent),
                  const SizedBox(width: 4),
                  Text(
                    post.location ?? 'No location listed',
                    style: const TextStyle(color: ShelPetTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                post.content,
                style: const TextStyle(fontSize: 14, height: 1.6, color: ShelPetTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: ShelPetTheme.primaryAccent.withOpacity(0.1),
                    child: Text(
                      post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary)),
                      Text(isFostering ? 'Foster Parent' : 'Giver Profile', style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/user-profile/${post.userId}');
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  label: Text(
                    isFostering ? 'Contact Foster Parent' : 'Contact Giver', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShelPetTheme.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final postsAsync = ref.watch(postsProvider);
    final currentUser = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: Text('My Favorites', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: postsAsync.when(
        data: (posts) {
          final favPosts = posts.where((p) => favorites.contains(p.id)).toList();

          if (favPosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: ShelPetTheme.textMuted.withOpacity(0.15)),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites saved yet',
                    style: GoogleFonts.outfit(color: ShelPetTheme.textMuted, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favPosts.length,
            itemBuilder: (context, index) {
              final post = favPosts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ShelPetTheme.primaryAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              post.type.toUpperCase(),
                              style: const TextStyle(color: ShelPetTheme.primaryAccent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(post.createdAt, style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(post.id),
                      ),
                    ),
                    if (post.image != null && post.image!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(post.image!, height: 160, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.content,
                            style: const TextStyle(fontSize: 14, height: 1.5, color: ShelPetTheme.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _showPostDetails(context, post, currentUser?.id),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('View Details'),
                            ),
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
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
