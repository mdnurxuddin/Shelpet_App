import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.0.141/shelpet_api"; 

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/auth/login.php"), body: jsonEncode({"email": email, "password": password}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, {String? nid, String? userCategory, String? address}) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/auth/register.php"), body: jsonEncode({"name": name, "email": email, "password": password, "nid": nid, "user_category": userCategory, "address": address}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<String?> uploadImage(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/upload_image.php"));
      request.files.add(await http.MultipartFile.fromPath('image', filePath, filename: filePath.split('/').last));
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      var result = jsonDecode(responseData.body);
      if (result['status'] == true) return result['data'];
    } catch (e) { print("Upload Error: $e"); }
    return null;
  }

  static Future<Map<String, dynamic>> submitVerification({required int userId, required String nidNumber, required String nidImage}) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/profile/submit_verification.php"), body: jsonEncode({"user_id": userId, "nid_number": nidNumber, "nid_image": nidImage}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<Map<String, dynamic>> toggleReaction(int userId, int postId) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/posts/toggle_reaction.php"), body: jsonEncode({"user_id": userId, "post_id": postId}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<Map<String, dynamic>> addComment(int userId, int postId, String content, {int? parentId}) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/posts/add_comment.php"), body: jsonEncode({"user_id": userId, "post_id": postId, "content": content, "parent_id": parentId}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<List<dynamic>> getComments(int postId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/posts/get_comments.php?post_id=$postId"));
      final data = jsonDecode(response.body);
      return data['status'] == true ? data['data'] ?? [] : [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> sendMessage(int senderId, int receiverId, String message) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/chat/send_message.php"), body: jsonEncode({"sender_id": senderId, "receiver_id": receiverId, "message": message}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<List<dynamic>> getChats(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/chat/get_chats.php?user_id=$userId"));
      final data = jsonDecode(response.body);
      return data['status'] == true ? data['data'] ?? [] : [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getMessages(int userId, int otherId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/chat/get_messages.php?user_id=$userId&other_id=$otherId"));
      final data = jsonDecode(response.body);
      return data['status'] == true ? data['data'] ?? [] : [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>?> getUserStats(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/profile/get_stats.php?user_id=$userId"));
      final data = jsonDecode(response.body);
      return data['status'] == true ? data['data'] : null;
    } catch (e) { return null; }
  }

  static Future<List<dynamic>> getUserReviews(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/profile/get_reviews.php?user_id=$userId"));
      final data = jsonDecode(response.body);
      return data['status'] == true ? data['data'] ?? [] : [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> submitReview({required int reviewerId, required int targetId, required double rating, String? comment}) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/profile/add_review.php"), body: jsonEncode({"reviewer_id": reviewerId, "target_id": targetId, "rating": rating, "comment": comment}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<Map<String, dynamic>> updatePostStatus(int postId, String status, {String? proofImage}) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/posts/update_post_status.php"), body: jsonEncode({"post_id": postId, "status": status, "proof_image": proofImage}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<Map<String, dynamic>> deletePost(int userId, int postId) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/posts/delete_post.php"), body: jsonEncode({"user_id": userId, "post_id": postId}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<List<dynamic>> getNotifications(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/notifications/get_notifications.php?user_id=$userId"));
      final data = jsonDecode(response.body);
      return data['status'] == true ? data['data'] ?? [] : [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/users/search_users.php?q=$query"));
      final data = jsonDecode(response.body);
      return data['status'] == true ? data['data'] ?? [] : [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> placeOrder({required int buyerId, required int productId, required String address, required String phone, int quantity = 1}) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/store/place_order.php"), body: jsonEncode({"buyer_id": buyerId, "product_id": productId, "address": address, "phone": phone, "quantity": quantity}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<Map<String, dynamic>> changePassword(int userId, String currentPassword, String newPassword) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/auth/change_password.php"), body: jsonEncode({"user_id": userId, "current_password": currentPassword, "new_password": newPassword}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<Map<String, dynamic>> deleteAccount(int userId) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/auth/delete_account.php"), body: jsonEncode({"user_id": userId}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<List<dynamic>> getPendingUsers() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/get_pending_users.php"));
      final data = jsonDecode(response.body);
      return data['status'] == true ? data['data'] ?? [] : [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> updateUserVerificationStatus(int userId, String status) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/admin/update_status.php"), body: jsonEncode({"user_id": userId, "status": status}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<List<dynamic>> getProducts(String category) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/store/get_products.php?category=$category"));
      final data = jsonDecode(response.body);
      return data['status'] == true ? data['data'] ?? [] : [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> createProduct({required int userId, required String name, required String description, required double price, required String category, String? image, int stock = 0}) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/store/create_product.php"), body: jsonEncode({"user_id": userId, "name": name, "description": description, "price": price, "category": category, "image": image, "stock": stock}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<Map<String, dynamic>> updateAvatar(int userId, String avatarUrl) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/profile/update_avatar.php"), body: jsonEncode({"user_id": userId, "avatar": avatarUrl}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }

  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/get_all_users.php"));
      final data = jsonDecode(response.body);
      return data['status'] == true ? data['data'] ?? [] : [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> deleteUser(int adminId, int targetUserId) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/admin/delete_user.php"), body: jsonEncode({"admin_id": adminId, "target_user_id": targetUserId}));
      return jsonDecode(response.body);
    } catch (e) { return {"status": false, "message": "Connection error: $e"}; }
  }
}
