import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'cloudinary_service.dart';

class DatabaseProduct {
  // Tham chiếu gốc đến toàn bộ Database để lấy thông tin User
  final DatabaseReference _rootRef = FirebaseDatabase.instance.ref();
  
  // Tham chiếu đến bảng 'posts' thay vì 'products' theo yêu cầu mới nhất
  final DatabaseReference _postRef = FirebaseDatabase.instance.ref("posts");
  
  final CloudinaryService _cloudinary = CloudinaryService();

  // 1. LẤY ĐỊA CHỈ NGƯỜI DÙNG TỪ PROFILE
  Future<String> getUserAddress(String userId) async {
    try {
      // Truy cập vào node 'users' để lấy địa chỉ đã lưu
      final snapshot = await _rootRef.child('users/$userId/address').get();
      return snapshot.exists ? snapshot.value.toString() : "Địa chỉ chưa cập nhật";
    } catch (e) {
      return "Lỗi lấy địa chỉ";
    }
  }

  // 2. ĐĂNG TIN MỚI VÀO MỤC 'POSTS'
  Future<bool> addPost({
    required String sellerId,
    required String title,
    required String category,
    required String type,
    required String price,
    required String description,
    required List<String> imageUrls, // Chuyển thành danh sách nhiều ảnh
    required String address,
  }) async {
    try {
      // Tạo một bài đăng mới với ID duy nhất
      final newPostRef = _postRef.push(); 
      await newPostRef.set({
        'postId': newPostRef.key,
        'sellerId': sellerId,
        'title': title,
        'category': category,
        'type': type,
        'price': type == 'Bán' ? price : '0', // Tự động đưa về 0 nếu là đồ tặng
        'description': description,
        'images': imageUrls, // Lưu mảng các đường dẫn ảnh
        'address': address,
        'status': 'pending', // Trạng thái chờ duyệt tin
        'createdAt': ServerValue.timestamp, // Thời gian lưu trên server
      });
      return true;
    } catch (e) {
      print("Lỗi thêm tin đăng: $e");
      return false;
    }
  }

  // 3. LẤY DANH SÁCH TIN ĐĂNG THEO TRẠNG THÁI
  Future<List<Map<dynamic, dynamic>>> getPostsByStatus(String userId, String status) async {
    try {
      // Lọc tin đăng theo ID của người bán
      DataSnapshot snapshot = await _postRef
          .orderByChild("sellerId")
          .equalTo(userId)
          .get();

      List<Map<dynamic, dynamic>> posts = [];
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value['status'] == status) {
            var postData = Map<dynamic, dynamic>.from(value);
            postData['id'] = key; 
            posts.add(postData);
          }
        });
      }
      return posts;
    } catch (e) {
      return [];
    }
  }

  // 4. XÓA TIN ĐĂNG
  Future<bool> deletePost(String postId) async {
    try {
      await _postRef.child(postId).remove();
      return true;
    } catch (e) {
      return false;
    }
  }
}