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
import 'package:shelpet/core/phone_verification_helper.dart';
import 'package:shelpet/core/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

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
                  child: CachedNetworkImage(
                    imageUrl: post.image!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[200]!,
                      highlightColor: Colors.grey[50]!,
                      child: Container(height: 250, color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
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
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile/${post.userId}');
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ShelPetTheme.lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: ShelPetTheme.primaryAccent.withOpacity(0.1),
                        backgroundImage: post.userAvatar != null && post.userAvatar!.isNotEmpty
                            ? NetworkImage(post.userAvatar!)
                            : null,
                        child: post.userAvatar == null || post.userAvatar!.isEmpty
                            ? Text(
                                post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                                style: const TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 18),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    post.userName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: ShelPetTheme.primaryAccent),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isFostering ? 'Verified Foster • Tap to view profile & history' : 'Pet Giver • Tap to view profile & history',
                              style: const TextStyle(color: ShelPetTheme.primaryAccent, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                          if (context.mounted) Navigator.pop(context);
                          ref.invalidate(postsProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isFostering ? 'Marked as Booked! 🎉' : 'Marked as Adopted! 🎉')),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response['message'] ?? 'Failed to update status.')),
                            );
                          }
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
                  Row(
                    children: [
                      if (post.displayContactNumber != null && post.displayContactNumber!.isNotEmpty) ...[
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              PhoneVerificationHelper.makePhoneCall(context, post.displayContactNumber!);
                            },
                            icon: const Icon(Icons.call, color: Colors.white),
                            label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (!PhoneVerificationHelper.checkPhoneAndPrompt(context, ref)) return;
                              if (!isVerified) {
                                _showVerifyAlert(context);
                                return;
                              }
                              Navigator.pop(context);
                              context.push('/chat/${post.userId}/${post.userName}');
                            },
                            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                            label: Text(
                              isFostering ? 'Message Foster' : 'Message Pet Giver', 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isVerified ? ShelPetTheme.primaryAccent : Colors.grey,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                    ],
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
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded, color: ShelPetTheme.primaryAccent, size: 26),
              tooltip: 'Adopted & Fostered History',
              onPressed: () => _showAdoptedHistorySheet(context, postsAsync),
            ),
            const SizedBox(width: 8),
          ],
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
                  // Apply status (active only) and location filters
                  var activePosts = posts.where((p) => p.status != 'done').toList();
                  if (_filterDistrict != null) {
                    activePosts = activePosts.where((p) => p.location != null && p.location!.contains(_filterDistrict!)).toList();
                  }
                  if (_filterCity != null) {
                    activePosts = activePosts.where((p) => p.location != null && p.location!.contains(_filterCity!)).toList();
                  }

                  final adoptionPosts = activePosts.where((p) => p.type == 'adoption').toList();
                  final fosteringPosts = activePosts.where((p) => p.type == 'fostering').toList();

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
                        ? CachedNetworkImage(
                            imageUrl: post.image!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[200]!,
                              highlightColor: Colors.grey[50]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image)),
                          )
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

  void _showAdoptedHistorySheet(BuildContext context, AsyncValue<List<Post>> postsAsync) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ShelPetTheme.primaryAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_rounded, color: ShelPetTheme.primaryAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adopted & Booked Archive',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Completed pet adoptions and paid fostering',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  labelColor: ShelPetTheme.primaryAccent,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: ShelPetTheme.primaryAccent,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: "Adopted Pets"),
                    Tab(text: "Paid Fosters"),
                  ],
                ),
                Expanded(
                  child: postsAsync.when(
                    data: (posts) {
                      final doneAdoptions = posts.where((p) => p.type == 'adoption' && p.status == 'done').toList();
                      final doneFosters = posts.where((p) => p.type == 'fostering' && p.status == 'done').toList();

                      return TabBarView(
                        children: [
                          _buildHistoryList(context, doneAdoptions, "No completed adoptions found yet."),
                          _buildHistoryList(context, doneFosters, "No completed fostering found yet."),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(BuildContext context, List<Post> posts, String emptyMessage) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final isFostering = post.type == 'fostering';
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
                child: post.image != null && post.image!.isNotEmpty
                    ? Image.network(post.image!, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildHistoryPlaceholder())
                    : _buildHistoryPlaceholder(),
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
                            color: (isFostering ? Colors.orange : Colors.green).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isFostering ? 'FOSTERED (৳${post.price.toInt()})' : 'HAPPY ADOPTED',
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: isFostering ? Colors.orange.shade800 : Colors.green),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          post.createdAt != null ? post.createdAt!.split('T')[0] : '',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            post.location ?? 'Bangladesh',
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
  }

  Widget _buildHistoryPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: ShelPetTheme.primaryAccent.withOpacity(0.1),
      child: const Icon(Icons.pets, color: ShelPetTheme.primaryAccent, size: 30),
    );
  }
}
