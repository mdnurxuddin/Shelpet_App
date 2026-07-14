import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelpet/core/api_service.dart';

class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String category;
  final String status;
  final double rating;
  final String role;
  final String? address;

  UserProfile({
    required this.id, required this.name, required this.email, this.avatar,
    required this.category, required this.status, required this.rating, required this.role,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'avatar': avatar,
    'user_category': category, 'verification_status': status, 'rating': rating, 'role': role,
    'address': address,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      category: json['user_category'] ?? 'Adoptor',
      status: json['verification_status'] ?? 'pending',
      rating: double.parse((json['rating'] ?? 5.0).toString()),
      role: json['role'] ?? 'user',
      address: json['address'],
    );
  }
}

class UserNotifier extends StateNotifier<UserProfile?> {
  UserNotifier() : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_session');
    if (userData != null) {
      state = UserProfile.fromJson(jsonDecode(userData));
      refreshUser();
    }
  }

  Future<void> refreshUser() async {
    if (state == null) return;
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/profile/get_profile.php?user_id=${state!.id}"),
      );
      final data = jsonDecode(response.body);
      if (data['status'] == true && data['data'] != null) {
        final freshUser = UserProfile.fromJson(data['data']);
        await setUser(freshUser);
      }
    } catch (e) {
      print("refreshUser error: $e");
    }
  }

  Future<void> setUser(UserProfile user) async {
    state = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserProfile?>((ref) => UserNotifier());

final userStatsProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, userId) async {
  return ApiService.getUserStats(userId);
});

final otherUserProfileProvider = FutureProvider.family<UserProfile?, int>((ref, userId) async {
  try {
    final response = await http.get(
      Uri.parse("${ApiService.baseUrl}/profile/get_profile.php?user_id=$userId"),
    );
    final data = jsonDecode(response.body);
    if (data['status'] == true) {
      return UserProfile.fromJson(data['data']);
    }
  } catch (e) {
    print("Error fetching other user profile: $e");
  }
  return null;
});

final userReviewsProvider = FutureProvider.family<List<dynamic>, int>((ref, userId) async {
  return ApiService.getUserReviews(userId);
});
