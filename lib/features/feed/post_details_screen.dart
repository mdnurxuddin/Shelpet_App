import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/features/feed/post_provider.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/favorites_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostDetailsScreen extends ConsumerWidget {
  final int postId;
  const PostDetailsScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(title: const Text('Post Details')),
      body: postsAsync.when(
        data: (posts) {
          try {
            final post = posts.firstWhere((p) => p.id == postId);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(post),
                  const SizedBox(height: 20),
                  if (post.image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(post.image!, width: double.infinity, fit: BoxFit.contain),
                    ),
                  const SizedBox(height: 20),
                  Text(post.content, style: GoogleFonts.inter(fontSize: 16, height: 1.6)),
                  const SizedBox(height: 20),
                  if (post.location != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: ShelPetTheme.secondaryAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(post.location!, style: const TextStyle(color: ShelPetTheme.textMuted)),
                      ],
                    ),
                ],
              ),
            );
          } catch (e) {
            return const Center(child: Text('Post not found or has been deleted.'));
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildPostHeader(Post post) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: ShelPetTheme.primaryAccent.withOpacity(0.1),
          backgroundImage: post.userAvatar != null ? NetworkImage(post.userAvatar!) : null,
          child: post.userAvatar == null ? Text(post.userName[0]) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(post.createdAt, style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
