import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelpet/core/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelpet/core/user_provider.dart';

/// Premium Post Model for ShelPet Community
class Post {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final String? image;
  final String type;
  final String createdAt;
  final String? location;
  final String? status;
  final double price;
  final int likesCount;
  final int commentsCount;
  final bool hasLiked;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.image,
    required this.type,
    required this.createdAt,
    this.location,
    this.status,
    required this.price,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.hasLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: int.parse(json['id'].toString()),
      userId: int.parse((json['user_id'] ?? 0).toString()),
      userName: json['user_name'] ?? 'Unknown User',
      userAvatar: json['user_avatar'],
      content: json['content'] ?? '',
      image: json['image'],
      type: json['type'] ?? 'feed',
      createdAt: json['created_at'] ?? '',
      location: json['location'],
      status: json['status'],
      price: double.parse((json['price'] ?? 0.0).toString()),
      likesCount: int.parse((json['likes_count'] ?? 0).toString()),
      commentsCount: int.parse((json['comments_count'] ?? 0).toString()),
      hasLiked: (json['has_liked'] ?? 0).toString() == '1' || json['has_liked'] == true,
    );
  }
}

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final user = ref.watch(userProvider);
  final userId = user?.id ?? 0;
  try {
    final response = await http.get(Uri.parse("${ApiService.baseUrl}/posts/get_posts.php?user_id=$userId"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        List<dynamic> list = data['data'];
        return list.map((e) => Post.fromJson(e)).toList();
      }
    }
  } catch (e) {
    print("Error fetching posts: $e");
  }
  return [];
});
