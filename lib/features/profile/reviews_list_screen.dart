import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/user_provider.dart';

class ReviewsListScreen extends ConsumerWidget {
  final int userId;
  final String userName;

  const ReviewsListScreen({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: Text('Reviews for $userName', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getUserReviews(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 64, color: ShelPetTheme.textMuted.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('No reviews yet', style: TextStyle(color: ShelPetTheme.textMuted)),
                ],
              ),
            );
          }

          final reviews = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final r = reviews[index];
              return _buildReviewTile(r);
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewTile(dynamic r) {
    final double rating = double.parse(r['rating'].toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: ShelPetTheme.primaryAccent.withOpacity(0.1),
                backgroundImage: r['reviewer_avatar'] != null ? NetworkImage(r['reviewer_avatar']) : null,
                child: r['reviewer_avatar'] == null 
                  ? Text(r['reviewer_name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['reviewer_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(r['created_at'].toString().split(' ')[0], style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 14,
                )),
              ),
            ],
          ),
          if (r['comment'] != null && r['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              r['comment'],
              style: const TextStyle(fontSize: 14, color: ShelPetTheme.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
