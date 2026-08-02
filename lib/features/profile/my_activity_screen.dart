import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/features/feed/post_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: Text('My Activity', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: postsAsync.when(
        data: (posts) {
          final myPosts = posts.where((p) => p.userId == user?.id).toList();

          if (myPosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu_rounded, size: 64, color: ShelPetTheme.textMuted.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('No activity found', style: TextStyle(color: ShelPetTheme.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: myPosts.length,
            itemBuilder: (context, index) {
              final post = myPosts[index];
              final bool isRescued = post.status == 'done';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: isRescued ? Colors.green.withOpacity(0.1) : Colors.black.withOpacity(0.03)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ShelPetTheme.primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            post.type.toUpperCase(),
                            style: const TextStyle(color: ShelPetTheme.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isRescued ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isRescued ? "RESCUED" : "ACTIVE",
                                style: TextStyle(
                                  color: isRescued ? Colors.green : Colors.orange.shade800,
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Post?'),
                                    content: const Text('Are you sure you want to delete this activity post?'),
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
                                if (confirm == true && user != null) {
                                  final response = await ApiService.deletePost(user.id, post.id);
                                  if (response['status'] == true) {
                                    ref.invalidate(postsProvider);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Full post text (no truncation)
                    Text(
                      post.content,
                      style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: ShelPetTheme.textPrimary),
                    ),
                    if (post.image != null && post.image!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: post.image!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 160,
                            color: Colors.grey.shade100,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => const SizedBox(),
                        ),
                      ),
                    ],
                    if (post.location != null && post.location!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: ShelPetTheme.secondaryAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              post.location!,
                              style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (post.type == 'fostering' && post.price > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Rate: ৳${post.price.toInt()} / day",
                        style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(post.createdAt, style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 11)),
                        if (post.type == 'rescue' && !isRescued)
                          TextButton.icon(
                            onPressed: () => _showRescueProofDialog(context, ref, post.id),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text("Mark Rescued", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  void _showRescueProofDialog(BuildContext context, WidgetRef ref, int postId) {
    File? proofImage;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Proof of Rescue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please upload a photo of the pet after rescue as proof.", style: TextStyle(fontSize: 13, color: ShelPetTheme.textSecondary)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (picked != null) setDialogState(() => proofImage = File(picked.path));
                },
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ShelPetTheme.lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: proofImage != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(proofImage!, fit: BoxFit.cover))
                    : const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading || proofImage == null ? null : () async {
                setDialogState(() => isLoading = true);
                
                // 1. Upload Proof Image
                final imageUrl = await ApiService.uploadImage(proofImage!.path);
                if (imageUrl == null) {
                   setDialogState(() => isLoading = false);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload image")));
                   return;
                }

                // 2. Update Status with Proof Link
                final res = await http.post(
                  Uri.parse("${ApiService.baseUrl}/posts/update_post_status.php"),
                  body: jsonEncode({
                    "post_id": postId,
                    "status": "done",
                    "proof_image": imageUrl
                  })
                );

                final data = jsonDecode(res.body);
                if (data['status'] == true) {
                  Navigator.pop(context);
                  ref.invalidate(postsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rescue confirmed with proof! 🎉")));
                }
              },
              child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
