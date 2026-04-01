import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'cloudinary_service.dart';

class DatabaseProduct {
  final DatabaseReference _rootRef = FirebaseDatabase.instance.ref();
  final DatabaseReference _postRef = FirebaseDatabase.instance.ref("posts");

  // 1. LẤY ĐỊA CHỈ NGƯỜI DÙNG (Giữ nguyên)
  Future<String> getUserAddress(String userId) async {
    try {
      final snapshot = await _rootRef.child('users/$userId/address').get();
      return snapshot.exists ? snapshot.value.toString() : "Địa chỉ chưa cập nhật";
    } catch (e) {
      return "Lỗi lấy địa chỉ";
    }
  }

  // 2. ĐĂNG TIN THEO DANH MỤC: /posts/{category}/{postId}
  Future<bool> addPost({
    required String sellerId,
    required String title,
    required String category, // Dùng biến này làm node cha
    required String type,
    required String price,
    required String description,
    required List<String> imageUrls,
    required String address,
  }) async {
    try {
      // THAY ĐỔI: Trỏ vào node danh mục trước khi push()
      final categoryPostsRef = _postRef.push(); 
      
      await categoryPostsRef.set({
        'postId': categoryPostsRef.key,
        'sellerId': sellerId,
        'title': title,
        'category': category,
        'type': type,
        'price': type == 'Bán' ? price : '0',
        'description': description,
        'images': imageUrls,
        'address': address,
        'status': 'pending',
        'createdAt': ServerValue.timestamp,
      });
      return true;
    } catch (e) {
      print("Lỗi thêm tin đăng: $e");
      return false;
    }
  }

  // 3. LẤY DANH SÁCH TIN THEO DANH MỤC (Tối ưu hiệu suất)
  Future<List<Map<dynamic, dynamic>>> getPostsByCategory(String category) async {
    try {
      // Truy cập thẳng vào node danh mục, không cần lọc toàn bộ database
      DataSnapshot snapshot = await _postRef.child(category).get();

      List<Map<dynamic, dynamic>> posts = [];
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          var postData = Map<dynamic, dynamic>.from(value);
          postData['id'] = key; 
          posts.add(postData);
        });
      }
      return posts;
    } catch (e) {
      return [];
    }
  }

  // 4. XÓA TIN ĐĂNG (Cần biết danh mục để tìm đúng đường dẫn)
  Future<bool> deletePost(String category, String postId) async {
    try {
      // Xóa tại: posts / {category} / {postId}
      await _postRef.child(category).child(postId).remove();
      return true;
    } catch (e) {
      return false;
    }
  }
}