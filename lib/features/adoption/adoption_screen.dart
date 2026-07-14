import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/features/feed/post_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shelpet/core/favorites_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/constants.dart';

class AdoptionScreen extends ConsumerStatefulWidget {
  const AdoptionScreen({super.key});

  @override
  ConsumerState<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends ConsumerState<AdoptionScreen> {
  String? _filterDistrict;
  String? _filterCity;
  List<String> _filterAvailableCities = [];

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

  void _showAdoptionDetails(BuildContext context, Post post, int? currentUserId, String type, bool isVerified) {
    final isFostering = type == 'fostering';
    final isOwner = post.userId == currentUserId;

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
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 220,
                      color: Colors.grey[100],
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isFostering ? 'Premium Fostering' : 'Adopt a Friend',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: post.status == 'done'
                          ? Colors.grey.withOpacity(0.1)
                          : (isFostering ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      post.status == 'done'
                          ? (isFostering ? 'BOOKED' : 'ADOPTED')
                          : (isFostering ? '৳${post.price.toInt()} / Day' : 'AVAILABLE'),
                      style: TextStyle(
                        color: post.status == 'done'
                            ? Colors.grey.shade700
                            : (isFostering ? Colors.orange.shade800 : Colors.green), 
                        fontWeight: FontWeight.bold, 
                        fontSize: 10,
                        letterSpacing: 0.5
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: ShelPetTheme.primaryAccent),
                  const SizedBox(width: 6),
                  Text(
                    post.location ?? 'Unknown Area',
                    style: const TextStyle(color: ShelPetTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                post.content,
                style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: ShelPetTheme.textSecondary),
              ),
              const SizedBox(height: 28),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 20),
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
                      Text(isFostering ? 'Verified Foster' : 'Pet Giver', style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isOwner) ...[
                if (post.status == 'done')
                  _buildStatusBanner(isFostering ? 'This slot is now booked!' : 'This pet has found a home!')
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final response = await ApiService.updatePostStatus(post.id, 'done');
                        if (response['status'] == true) {
                          Navigator.pop(context);
                          ref.invalidate(postsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isFostering ? 'Marked as Booked!' : 'Marked as Adopted!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        isFostering ? 'Mark as Booked' : 'Mark as Adopted', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
              ] else ...[
                if (post.status == 'done')
                  _buildStatusBanner(isFostering ? 'Already Booked' : 'Already Adopted')
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!isVerified) {
                           _showVerifyAlert(context);
                           return;
                        }
                        Navigator.pop(context);
                        context.push('/chat/${post.userId}/${post.userName}');
                      },
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      label: Text(
                        isFostering ? 'Message Foster Parent' : 'Message Pet Giver', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isVerified ? ShelPetTheme.primaryAccent : Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);
    final currentUser = ref.watch(userProvider);
    final bool isVerified = currentUser?.status == 'verified';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: ShelPetTheme.lightBg,
        appBar: AppBar(
          title: Text(
            'ShelPet Care',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: ShelPetTheme.textPrimary),
          ),
          bottom: TabBar(
            labelColor: ShelPetTheme.primaryAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: ShelPetTheme.primaryAccent,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: "Pet Adoption"),
              Tab(text: "Paid Fostering"),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildLocationFilter(),
            Expanded(
              child: postsAsync.when(
                data: (posts) {
                  // Apply location filters
                  var filtered = posts;
                  if (_filterDistrict != null) {
                    filtered = filtered.where((p) => p.location != null && p.location!.contains(_filterDistrict!)).toList();
                  }
                  if (_filterCity != null) {
                    filtered = filtered.where((p) => p.location != null && p.location!.contains(_filterCity!)).toList();
                  }

                  final adoptionPosts = filtered.where((p) => p.type == 'adoption').toList();
                  final fosteringPosts = filtered.where((p) => p.type == 'fostering').toList();

                  return TabBarView(
                    children: [
                      _buildPostsGrid(context, adoptionPosts, currentUser?.id, "No pets found in this area", "adoption", isVerified),
                      _buildPostsGrid(context, fosteringPosts, currentUser?.id, "No fostering found in this area", "fostering", isVerified),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _filterDistrict,
                    hint: const Text('District', style: TextStyle(fontSize: 12)),
                    decoration: InputDecoration(
                      isDense: true, contentPadding: const EdgeInsets.all(12),
                      filled: true, fillColor: ShelPetTheme.lightBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Districts', style: TextStyle(fontSize: 12))),
                      ...AppConstants.allDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _filterDistrict = val;
                        _filterCity = null;
                        _filterAvailableCities = val != null ? AppConstants.bdDistricts[val]! : [];
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _filterCity,
                    hint: const Text('City/Area', style: TextStyle(fontSize: 12)),
                    decoration: InputDecoration(
                      isDense: true, contentPadding: const EdgeInsets.all(12),
                      filled: true, fillColor: ShelPetTheme.lightBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Cities', style: TextStyle(fontSize: 12))),
                      ..._filterAvailableCities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))),
                    ],
                    onChanged: (val) => setState(() => _filterCity = val),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(BuildContext context, List<Post> filteredPosts, int? currentUserId, String emptyMessage, String type, bool isVerified) {
    if (filteredPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 64, color: ShelPetTheme.textMuted.withOpacity(0.15)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 50),
          child: _buildModernAdoptionCard(context, post, currentUserId, type, isVerified),
        );
      },
    );
  }

  Widget _buildModernAdoptionCard(BuildContext context, Post post, int? currentUserId, String type, bool isVerified) {
    final bool isFostering = type == 'fostering';
    final bool isDone = post.status == 'done';
    
    final words = post.content.trim().split(' ');
    String petName = words.isNotEmpty ? words.first : 'Pet';
    if(petName.length > 10) petName = petName.substring(0, 8) + '...';

    return GestureDetector(
      onTap: () => _showAdoptionDetails(context, post, currentUserId, type, isVerified),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    child: post.image != null && post.image!.isNotEmpty
                        ? Image.network(post.image!, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                        : Container(color: Colors.grey[100], child: const Center(child: Icon(Icons.pets, color: Colors.grey))),
                  ),
                  if (isDone)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Text(isFostering ? 'BOOKED' : 'ADOPTED', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          petName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: ShelPetTheme.textPrimary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (!isVerified) { _showVerifyAlert(context); return; }
                          ref.read(favoritesProvider.notifier).toggleFavorite(post.id);
                        },
                        child: Icon(
                          ref.watch(favoritesProvider).contains(post.id) ? Icons.favorite : Icons.favorite_border,
                          color: ref.watch(favoritesProvider).contains(post.id) ? Colors.red : Colors.grey.shade400,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 10, color: ShelPetTheme.secondaryAccent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.location ?? 'Dhaka',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFostering ? Colors.orange.withOpacity(0.08) : ShelPetTheme.primaryAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isFostering ? '৳${post.price.toInt()}' : 'ADOPT',
                          style: TextStyle(
                            color: isFostering ? Colors.orange.shade800 : ShelPetTheme.primaryAccent, 
                            fontSize: 9, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
